// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import CoreLocation
import Foundation

/// Fay hattı veri koleksiyonu kök modeli.
struct FaultLineCollection: Codable {
    let version: String
    let faultLines: [FaultLine]
}

/// Tek bir fay hattı segmenti.
struct FaultLine: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let startLatitude: Double
    let startLongitude: Double
    let endLatitude: Double
    let endLongitude: Double
    let magnitude: String
    let description: String

    var startCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    var endCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }
}

/// Deprem risk seviyeleri.
enum RiskLevel: String, CaseIterable {
    case low = "Düşük"
    case medium = "Orta"
    case high = "Yüksek"

    /// Fay mesafesine göre risk seviyesi belirler (km).
    static func from(distanceKm: Double) -> RiskLevel {
        if distanceKm < 5 { return .high }
        if distanceKm < 15 { return .medium }
        return .low
    }
}
