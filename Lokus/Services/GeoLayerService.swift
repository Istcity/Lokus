// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation
import MapKit

/// Backend GeoJSON katmanlarını bbox ile yükler.
actor GeoLayerService {
    static let shared = GeoLayerService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        session = URLSession(configuration: config)
    }

    func fetchLayers(
        region: MKCoordinateRegion,
        active: Set<MapOverlayType>
    ) async -> [GeoLayerFeature] {
        guard AppConfiguration.isGeoBackendConfigured,
              let base = AppConfiguration.geoBackendURL else { return [] }

        let geoLayers = active.filter { $0 != .faultLines }
        guard !geoLayers.isEmpty else { return [] }

        let bbox = bbox(for: region)
        var all: [GeoLayerFeature] = []

        await withTaskGroup(of: [GeoLayerFeature].self) { group in
            for layer in geoLayers {
                group.addTask {
                    await self.fetchLayer(layer: layer, base: base, bbox: bbox)
                }
            }
            for await features in group {
                all.append(contentsOf: features)
            }
        }
        return all
    }

    private func fetchLayer(
        layer: MapOverlayType,
        base: URL,
        bbox: (minLng: Double, minLat: Double, maxLng: Double, maxLat: Double)
    ) async -> [GeoLayerFeature] {
        var components = URLComponents(
            url: base.appendingPathComponent("api/layers/\(layer.rawValue)/geojson"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "min_lng", value: String(bbox.minLng)),
            URLQueryItem(name: "min_lat", value: String(bbox.minLat)),
            URLQueryItem(name: "max_lng", value: String(bbox.maxLng)),
            URLQueryItem(name: "max_lat", value: String(bbox.maxLat))
        ]
        guard let url = components.url else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            return GeoLayerParser.parse(data: data, layer: layer)
        } catch {
            return []
        }
    }

    private func bbox(for region: MKCoordinateRegion) -> (minLng: Double, minLat: Double, maxLng: Double, maxLat: Double) {
        let center = region.center
        let span = region.span
        let minLat = center.latitude - span.latitudeDelta / 2
        let maxLat = center.latitude + span.latitudeDelta / 2
        let minLng = center.longitude - span.longitudeDelta / 2
        let maxLng = center.longitude + span.longitudeDelta / 2
        return (minLng, minLat, maxLng, maxLat)
    }
}
