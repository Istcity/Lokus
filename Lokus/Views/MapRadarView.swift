// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import MapKit
import SwiftUI

/// Tam ekran harita radarı — konum takibi ve dokunuş/pin desteği.
struct MapRadarView: View {
    @StateObject private var viewModel = MapViewModel()
    @ObservedObject private var router = AppRouter.shared
    @State private var showInfoSheet = false
    @State private var sheetDetent: PresentationDetent = MapInfoSheetDetents.half

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                mapContent
                    .mapStyle(.standard(elevation: .realistic))
                    .ignoresSafeArea()
                    .simultaneousGesture(tapSelectGesture(proxy: proxy))
                    .simultaneousGesture(longPressGesture(proxy: proxy))
            }
            .overlay(alignment: .top) {
                topBadges
                    .padding(.top, 8)
            }
            .overlay(alignment: .bottom) {
                mapControls
                    .padding(.horizontal, 16)
                    .padding(.bottom, peekBarVisible ? 88 : 12)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if peekBarVisible {
                    MapInfoPeekBar(
                        title: viewModel.selectedVillage?.name ?? "Seçili konum",
                        subtitle: peekSubtitle,
                        onOpen: {
                            sheetDetent = MapInfoSheetDetents.half
                            showInfoSheet = true
                        },
                        onDismiss: {
                            viewModel.clearSelection()
                        }
                    )
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Keşfet")
            .navigationBarTitleDisplayMode(.inline)
            .lokusNavigationBarLogo()
            .sheet(isPresented: $showInfoSheet, onDismiss: {
                // Aşağı kaydırınca seçim kalır — peek çubuk görünür.
            }) {
                infoSheetContent
                    .mapInfoSheetStyle(detent: $sheetDetent)
            }
            .alert(
                "Hata",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.startLocationTracking()
                viewModel.refreshGeoLayers()
                if let pending = router.pendingCoordinate {
                    await viewModel.handlePendingCoordinate(pending)
                    router.pendingCoordinate = nil
                    presentInfoSheet()
                }
            }
            .onChange(of: router.pendingCoordinate?.latitude) { _, _ in
                guard let coordinate = router.pendingCoordinate else { return }
                Task {
                    await viewModel.handlePendingCoordinate(coordinate)
                    router.pendingCoordinate = nil
                    presentInfoSheet()
                }
            }
            .onChange(of: viewModel.selectedVillage) { _, newValue in
                if newValue != nil {
                    presentInfoSheet()
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: peekBarVisible)
            .lokusAdBanner()
        }
    }

    private var peekBarVisible: Bool {
        viewModel.selectedVillage != nil && !showInfoSheet
    }

    private var peekSubtitle: String? {
        guard let settlement = viewModel.resolvedSettlement else { return nil }
        return "\(settlement.districtName), \(settlement.provinceName)"
    }

    @ViewBuilder
    private var infoSheetContent: some View {
        if viewModel.selectedVillage != nil {
            FeatureGateView(featureName: "Bölge Analizi") {
                Group {
                    if let geo = viewModel.locationAnalysisResult {
                        LocationAnalysisSheet(
                            data: geo,
                            settlement: viewModel.resolvedSettlement,
                            coordinate: viewModel.lastTappedCoordinate,
                            tkgmLookup: viewModel.tkgmParcelLookup,
                            onDismiss: dismissInfoSheetAndClear,
                            showCachedBanner: viewModel.showingCachedGeoData
                        )
                    } else if let village = viewModel.selectedVillage {
                        BottomSheetView(
                            village: village,
                            coordinate: viewModel.lastTappedCoordinate,
                            settlement: viewModel.resolvedSettlement,
                            nearestFault: viewModel.nearestFault,
                            tkgmLookup: viewModel.tkgmParcelLookup,
                            onDismiss: dismissInfoSheetAndClear,
                            onZoningUpdated: {
                                Task {
                                    await viewModel.resolveVillage(
                                        for: viewModel.lastTappedCoordinate,
                                        addPin: !viewModel.pins.isEmpty,
                                        updateSelection: true
                                    )
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private func presentInfoSheet() {
        sheetDetent = MapInfoSheetDetents.half
        showInfoSheet = true
    }

    private func dismissInfoSheetAndClear() {
        showInfoSheet = false
        viewModel.clearSelection()
    }

    private var mapContent: some View {
        Map(position: $viewModel.mapPosition, interactionModes: .all) {
            UserAnnotation()
            selectionMarker
            geoLayerOverlays
            faultOverlays
            pinAnnotations
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.updateVisibleRegion(context.region)
        }
    }

    @MapContentBuilder
    private var selectionMarker: some MapContent {
        if viewModel.selectedVillage != nil, viewModel.pins.isEmpty {
            Annotation("Seçili", coordinate: viewModel.lastTappedCoordinate) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color("AccentOrange"))
                    .shadow(radius: 2)
            }
        }
    }

    @MapContentBuilder
    private var geoLayerOverlays: some MapContent {
        ForEach(viewModel.geoLayerFeatures.filter { viewModel.activeOverlays.contains($0.layer) }) { feature in
            switch feature.geometry {
            case .polygon(let coords):
                MapPolygon(coordinates: coords)
                    .foregroundStyle(feature.fillColor)
                    .stroke(feature.strokeColor, lineWidth: 2)
            case .polyline(let coords):
                MapPolyline(coordinates: coords)
                    .stroke(feature.strokeColor, lineWidth: 3)
            }
        }
    }

    @MapContentBuilder
    private var faultOverlays: some MapContent {
        if viewModel.activeOverlays.contains(.faultLines) {
            ForEach(viewModel.faultLines) { fault in
                MapPolyline(coordinates: [fault.startCoordinate, fault.endCoordinate])
                    .stroke(Color("DangerRed").opacity(0.8), lineWidth: 2)
            }
        }
    }

    @MapContentBuilder
    private var pinAnnotations: some MapContent {
        ForEach(viewModel.pins) { pin in
            Annotation(pin.title, coordinate: pin.coordinate) {
                PinView(pin: pin)
                    .onTapGesture {
                        viewModel.selectPin(pin)
                        presentInfoSheet()
                    }
            }
        }
    }

    private func tapSelectGesture(proxy: MapProxy) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard let coordinate = proxy.convert(value.location, from: .local) else { return }
                viewModel.selectLocation(at: coordinate)
                presentInfoSheet()
            }
    }

    private func longPressGesture(proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onEnded { value in
                switch value {
                case .second(true, let drag):
                    if let location = drag?.location,
                       let coordinate = proxy.convert(location, from: .local) {
                        viewModel.addPin(at: coordinate)
                        presentInfoSheet()
                    }
                default:
                    break
                }
            }
    }

    @ViewBuilder
    private var topBadges: some View {
        if let selected = viewModel.selectedVillage, showInfoSheet {
            SelectedLocationBadge(village: selected, isPinned: !viewModel.pins.isEmpty)
        } else if let nearest = viewModel.nearestVillage, viewModel.selectedVillage == nil {
            NearestLocationBadge(village: nearest)
        }

        if viewModel.isLoading {
            ProgressView("Konum analiz ediliyor…")
                .padding(10)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var mapControls: some View {
        HStack {
            MapLayerToolbar(activeOverlays: $viewModel.activeOverlays)
            Spacer()
            Button {
                Task { await viewModel.recenterToUser() }
            } label: {
                Image(systemName: viewModel.isFollowingUser ? "location.fill" : "location")
                    .font(.title3)
                    .foregroundStyle(Color("AccentOrange"))
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(radius: 2)
            }
            .accessibilityLabel("Konumuma dön")
        }
    }
}

/// Harita pin görünümü.
struct PinView: View {
    let pin: MapPin

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundStyle(Color("AccentOrange"))
                .shadow(radius: 2)
            Text(pin.title)
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

/// Seçili bölge rozeti.
struct SelectedLocationBadge: View {
    let village: Village
    let isPinned: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isPinned ? "mappin.and.ellipse" : "scope")
                .foregroundStyle(Color("AccentOrange"))
            Text(isPinned ? "Seçili: \(village.name)" : "Bölge: \(village.name)")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal)
    }
}

/// En yakın yerleşim rozeti.
struct NearestLocationBadge: View {
    let village: Village

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .foregroundStyle(Color("AccentOrange"))
            Text("En yakın: \(village.name)")
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal)
    }
}

#Preview {
    MapRadarView()
}
