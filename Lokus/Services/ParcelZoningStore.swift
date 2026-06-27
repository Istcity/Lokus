// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// Kullanıcı çap / e-Plan imar girişlerini saklar.
@MainActor
final class ParcelZoningStore: ObservableObject {
    static let shared = ParcelZoningStore()

    @Published private(set) var overrides: [String: ParcelZoningOverride] = [:]

    private let storageKey = "lokus_parcel_zoning"

    private init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let list = try? JSONDecoder().decode([ParcelZoningOverride].self, from: data) else {
            overrides = [:]
            return
        }
        overrides = Dictionary(uniqueKeysWithValues: list.map { ($0.locationKey, $0) })
    }

    func override(for coordinate: CLLocationCoordinate2D) -> ParcelZoningOverride? {
        let key = ParcelZoningOverride.locationKey(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return overrides[key]
    }

    func save(_ override: ParcelZoningOverride) {
        overrides[override.locationKey] = override
        persist()
    }

    func applyOverride(to village: Village, at coordinate: CLLocationCoordinate2D) -> Village {
        guard let override = override(for: coordinate) else { return village }
        return Village(
            name: village.name,
            housePricePerM2: village.housePricePerM2,
            landPricePerM2: village.landPricePerM2,
            zoning: override.zoningInfo,
            infrastructure: village.infrastructure,
            notes: "Çap ref: \(override.capReference). \(override.notes)"
        )
    }

    private func persist() {
        let list = Array(overrides.values)
        guard let data = try? JSONEncoder().encode(list) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
