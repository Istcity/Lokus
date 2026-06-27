// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI

/// Harita üzerindeki pin modeli.
struct MapPin: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String

    static func == (lhs: MapPin, rhs: MapPin) -> Bool {
        lhs.id == rhs.id
    }
}

/// Konum izni ve güncellemeleri yöneten yardımcı sınıf.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func requestSingleLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

/// Keşfet haritası durumunu yöneten ViewModel.
@MainActor
final class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @Published var mapPosition: MapCameraPosition = .automatic
    @Published var pins: [MapPin] = []
    @Published var nearestVillage: Village?
    @Published var selectedVillage: Village?
    @Published var resolvedSettlement: ResolvedSettlement?
    @Published var isLoading = false
    @Published var lastTappedCoordinate = CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597)
    @Published var errorMessage: String?
    @Published private(set) var isFollowingUser = true
    @Published private(set) var userCoordinate: CLLocationCoordinate2D?
    @Published var faultLines: [FaultLine] = []
    @Published var showFaultLines = true
    @Published private(set) var nearestFault: (fault: FaultLine, distanceKm: Double)?
    @Published var locationAnalysisResult: LocationAnalysisResult?
    @Published var showingCachedGeoData = false
    @Published var activeOverlays: Set<MapOverlayType> = [.faultLines]
    @Published private(set) var geoLayerFeatures: [GeoLayerFeature] = []
    @Published private(set) var tkgmParcelLookup: TKGMParcelResult?

    private let geoService = GeoQueryService.shared
    private let geoLayerService = GeoLayerService.shared
    private var layerRefreshTask: Task<Void, Never>?

    private let settlementResolver = SettlementResolver()
    private let locationManager = LocationManager()
    private let dataLoader = DataLoader()
    private var cancellables = Set<AnyCancellable>()
    private var hasReceivedInitialLocation = false

    init() {
        faultLines = (try? dataLoader.loadFaultLines()) ?? []
        locationManager.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                Task { @MainActor in
                    await self?.handleUserLocationUpdate(coordinate)
                }
            }
            .store(in: &cancellables)

        $activeOverlays
            .dropFirst()
            .sink { [weak self] _ in
                self?.refreshGeoLayers()
            }
            .store(in: &cancellables)
    }

    /// Harita bbox değişince katmanları yeniden yükler.
    func updateVisibleRegion(_ newRegion: MKCoordinateRegion) {
        region = newRegion
        refreshGeoLayers()
    }

    func refreshGeoLayers() {
        layerRefreshTask?.cancel()
        guard AppConfiguration.isGeoBackendConfigured else {
            geoLayerFeatures = []
            return
        }
        let snapshotRegion = region
        let snapshotOverlays = activeOverlays
        layerRefreshTask = Task {
            let features = await geoLayerService.fetchLayers(
                region: snapshotRegion,
                active: snapshotOverlays
            )
            guard !Task.isCancelled else { return }
            geoLayerFeatures = features
        }
    }

    /// Konum izni ister ve ilk köy tespitini başlatır.
    func startLocationTracking() async {
        isLoading = true
        defer { isLoading = false }

        locationManager.requestPermission()
        locationManager.startUpdating()

        if locationManager.authorizationStatus == .denied
            || locationManager.authorizationStatus == .restricted {
            errorMessage = LokusError.locationDenied.errorDescription
        }
    }

    /// Haritada tek dokunuşla konum seçer (pin eklemez).
    func selectLocation(at coordinate: CLLocationCoordinate2D) {
        isFollowingUser = false
        locationManager.stopUpdating()
        lastTappedCoordinate = coordinate
        Task {
            await resolveVillage(for: coordinate, addPin: false, updateSelection: true)
        }
    }

    /// Long press sonrası pin ekler ve köy tespiti yapar.
    func addPin(at coordinate: CLLocationCoordinate2D) {
        isFollowingUser = false
        locationManager.stopUpdating()
        lastTappedCoordinate = coordinate
        Task {
            await resolveVillage(for: coordinate, addPin: true, updateSelection: true)
        }
    }

    /// Pin seçildiğinde bottom sheet için köyü ayarlar.
    func selectPin(_ pin: MapPin) {
        isFollowingUser = false
        locationManager.stopUpdating()
        Task {
            await resolveVillage(for: pin.coordinate, addPin: false, updateSelection: true)
        }
    }

    /// Kullanıcı konumuna geri döner.
    func recenterToUser() async {
        isFollowingUser = true
        pins = []
        selectedVillage = nil
        resolvedSettlement = nil

        if let coordinate = userCoordinate ?? locationManager.currentLocation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapPosition = .region(region)
            await resolveVillage(for: coordinate, addPin: false, updateSelection: false)
        }

        locationManager.startUpdating()
    }

    /// Seçimi temizler ve alt paneli kapatır.
    func clearSelection() {
        selectedVillage = nil
        resolvedSettlement = nil
        locationAnalysisResult = nil
        showingCachedGeoData = false
        tkgmParcelLookup = nil
        pins = []
    }

    private func registerMissingOfficialQueries(
        at coordinate: CLLocationCoordinate2D,
        settlement: ResolvedSettlement,
        geo: LocationAnalysisResult?
    ) {
        let log = OfficialQueryLogStore.shared
        if geo?.parcel == nil {
            log.recordPending(
                kind: .parcel,
                coordinate: coordinate,
                settlement: settlement,
                tkgm: tkgmParcelLookup
            )
        }
        if geo?.zoning == nil {
            log.recordPending(kind: .zoning, coordinate: coordinate, settlement: settlement)
        }
    }

    private func fetchGeoAnalysis(at coordinate: CLLocationCoordinate2D) async -> LocationAnalysisResult? {
        guard AppConfiguration.isGeoBackendConfigured else { return nil }

        do {
            showingCachedGeoData = false
            var result = try await geoService.queryLocation(
                lat: coordinate.latitude,
                lng: coordinate.longitude
            )
            result = await enrichWithLocalPOI(result, coordinate: coordinate)
            return result
        } catch {
            if let cached = await geoService.cachedResult(for: coordinate) {
                showingCachedGeoData = true
                return await enrichWithLocalPOI(cached, coordinate: coordinate)
            }
            return nil
        }
    }

    private func enrichWithLocalPOI(
        _ result: LocationAnalysisResult,
        coordinate: CLLocationCoordinate2D
    ) async -> LocationAnalysisResult {
        let poi = result.poi
        let hasPOI = !poi.okullar.isEmpty || !poi.hastaneler.isEmpty
            || !poi.marketler.isEmpty || !poi.parklar.isEmpty || !poi.duraklar.isEmpty
        guard !hasPOI else { return result }

        let localPOI = await POISearchService.searchNearby(coordinate: coordinate)
        let hasLocal = !localPOI.okullar.isEmpty || !localPOI.hastaneler.isEmpty
            || !localPOI.marketler.isEmpty || !localPOI.parklar.isEmpty || !localPOI.duraklar.isEmpty
        guard hasLocal else { return result }

        var sources = result.dataSources
        sources.append(
            GeoDataSource(
                katman: "poi",
                kaynak: "Apple MapKit (yerel)",
                guncellemeTarihi: ISO8601DateFormatter().string(from: Date()).prefix(10).description,
                lisans: "Apple Maps"
            )
        )

        return LocationAnalysisResult(
            parcel: result.parcel,
            zoning: result.zoning,
            infrastructure: result.infrastructure,
            poi: localPOI,
            dataSources: sources,
            cached: result.cached
        )
    }

    /// CLGeocoder + idari indeks + TurkiyeAPI ile yerleşim tespiti yapar.
    func resolveVillage(
        for coordinate: CLLocationCoordinate2D,
        addPin: Bool,
        updateSelection: Bool
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if updateSelection || isFollowingUser {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
            mapPosition = .region(region)
        }

        refreshGeoLayers()

        do {
            async let resolvedTask = settlementResolver.resolve(at: coordinate)
            async let geoTask: LocationAnalysisResult? = fetchGeoAnalysis(at: coordinate)
            async let tkgmTask = TKGMParcelService.shared.lookup(at: coordinate)

            let resolved = try await resolvedTask
            locationAnalysisResult = await geoTask
            tkgmParcelLookup = await tkgmTask

            registerMissingOfficialQueries(
                at: coordinate,
                settlement: resolved,
                geo: locationAnalysisResult
            )

            resolvedSettlement = updateSelection ? resolved : resolvedSettlement
            nearestVillage = resolved.village
            if updateSelection {
                selectedVillage = resolved.village
            }

            assessFaultDistance(at: coordinate)

            AppGroupManager.shared.saveLastViewedRegion(
                name: resolved.settlementName,
                district: resolved.districtName,
                province: resolved.provinceName,
                housePrice: resolved.village.housePricePerM2,
                coordinate: coordinate
            )

            if addPin {
                let pin = MapPin(coordinate: coordinate, title: resolved.settlementName)
                pins = [pin]
            }
        } catch let error as LokusError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = LokusError.geocodingFailed.errorDescription
        }
    }

    private func handleUserLocationUpdate(_ coordinate: CLLocationCoordinate2D) async {
        userCoordinate = coordinate

        guard isFollowingUser else { return }

        if !hasReceivedInitialLocation {
            hasReceivedInitialLocation = true
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapPosition = .region(region)
            await resolveVillage(for: coordinate, addPin: false, updateSelection: true)
            locationManager.stopUpdating()
            return
        }

        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapPosition = .region(region)
    }

    func handlePendingCoordinate(_ coordinate: CLLocationCoordinate2D) async {
        isFollowingUser = false
        locationManager.stopUpdating()
        await resolveVillage(for: coordinate, addPin: true, updateSelection: true)
    }

    private func assessFaultDistance(at coordinate: CLLocationCoordinate2D) {
        var best: (FaultLine, Double)?
        for fault in faultLines {
            let distance = GeoUtils.distanceToSegment(
                point: coordinate,
                segmentStart: fault.startCoordinate,
                segmentEnd: fault.endCoordinate
            )
            if best == nil || distance < best!.1 {
                best = (fault, distance)
            }
        }
        nearestFault = best
    }
}
