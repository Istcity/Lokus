// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// Son geo sorgu sonucu önbelleği (7 gün TTL).
actor GeoQueryCache {
    static let shared = GeoQueryCache()

    private let ttl: TimeInterval = 7 * 24 * 3600
    private let storageKey = "lokus_geo_query_cache"

    private struct Entry: Codable {
        let lat: Double
        let lng: Double
        let savedAt: Date
        let result: LocationAnalysisResult
    }

    private init() {}

    func save(_ result: LocationAnalysisResult, for coordinate: CLLocationCoordinate2D) {
        var entries = loadAll().filter {
            Date().timeIntervalSince($0.savedAt) < ttl
        }
        entries.removeAll {
            abs($0.lat - coordinate.latitude) < 0.0001
                && abs($0.lng - coordinate.longitude) < 0.0001
        }
        entries.insert(
            Entry(lat: coordinate.latitude, lng: coordinate.longitude, savedAt: Date(), result: result),
            at: 0
        )
        entries = Array(entries.prefix(20))
        persist(entries)
    }

    func load(for coordinate: CLLocationCoordinate2D) -> LocationAnalysisResult? {
        loadAll().first {
            abs($0.lat - coordinate.latitude) < 0.0005
                && abs($0.lng - coordinate.longitude) < 0.0005
                && Date().timeIntervalSince($0.savedAt) < ttl
        }?.result
    }

    private func loadAll() -> [Entry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return entries
    }

    private func persist(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
