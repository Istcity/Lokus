// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// Kayıtlı bölgeleri yönetir (App Group — widget ile paylaşılır).
@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var favorites: [SavedLocation] = []

    private let storageKey = "lokus_favorites"
    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: Constants.appGroupID)
        load()
    }

    func load() {
        guard let data = defaults?.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
            favorites = []
            return
        }
        favorites = decoded.sorted { $0.savedAt > $1.savedAt }
    }

    func save(_ location: SavedLocation) {
        if let index = favorites.firstIndex(where: { $0.id == location.id }) {
            favorites[index] = location
        } else {
            favorites.insert(location, at: 0)
        }
        persist()
    }

    func add(from settlement: ResolvedSettlement, coordinate: CLLocationCoordinate2D) {
        let saved = SavedLocation(
            name: settlement.settlementName,
            coordinate: coordinate,
            provinceName: settlement.provinceName,
            districtName: settlement.districtName,
            village: settlement.village
        )
        if favorites.contains(where: {
            GeoUtils.normalize($0.name) == GeoUtils.normalize(saved.name)
                && $0.districtName == saved.districtName
        }) {
            return
        }
        favorites.insert(saved, at: 0)
        persist()
        AppGroupManager.shared.saveLastViewedRegion(saved)
    }

    func remove(_ location: SavedLocation) {
        favorites.removeAll { $0.id == location.id }
        persist()
    }

    func contains(name: String, district: String) -> Bool {
        favorites.contains {
            GeoUtils.normalize($0.name) == GeoUtils.normalize(name) && $0.districtName == district
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        defaults?.set(data, forKey: storageKey)
    }
}
