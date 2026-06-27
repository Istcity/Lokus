// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import MapKit

/// MapKit Local Search — backend POI boşsa yerel tamamlama.
enum POISearchService {
    /// Yakındaki okul, hastane, market, park ve durakları arar.
    static func searchNearby(
        coordinate: CLLocationCoordinate2D,
        radiusM: Int = 500
    ) async -> GeoPOIData {
        async let schools = search(query: "okul", coordinate: coordinate, radiusM: radiusM)
        async let hospitals = search(query: "hastane", coordinate: coordinate, radiusM: radiusM)
        async let markets = search(query: "market", coordinate: coordinate, radiusM: radiusM)
        async let parks = search(query: "park", coordinate: coordinate, radiusM: radiusM)
        async let transit = search(query: "otobüs durağı", coordinate: coordinate, radiusM: radiusM)

        return GeoPOIData(
            okullar: await schools,
            hastaneler: await hospitals,
            marketler: await markets,
            parklar: await parks,
            duraklar: await transit
        )
    }

    private static func search(
        query: String,
        coordinate: CLLocationCoordinate2D,
        radiusM: Int
    ) async -> [GeoPOIItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: Double(radiusM * 2),
            longitudinalMeters: Double(radiusM * 2)
        )
        request.resultTypes = .pointOfInterest

        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.prefix(8).compactMap { item in
                guard let loc = item.placemark.location else { return nil }
                let distance = Int(loc.distance(from: CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )))
                return GeoPOIItem(
                    name: item.name ?? query,
                    category: query,
                    distanceM: distance,
                    lat: loc.coordinate.latitude,
                    lng: loc.coordinate.longitude
                )
            }
        } catch {
            return []
        }
    }
}
