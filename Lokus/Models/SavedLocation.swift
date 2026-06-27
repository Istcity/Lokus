// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// Kullanıcının kaydettiği bölge.
struct SavedLocation: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    let latitude: Double
    let longitude: Double
    var provinceName: String
    var districtName: String
    var village: Village
    var savedAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        provinceName: String,
        districtName: String,
        village: Village,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.provinceName = provinceName
        self.districtName = districtName
        self.village = village
        self.savedAt = savedAt
    }
}
