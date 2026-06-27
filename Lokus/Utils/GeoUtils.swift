// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import CoreLocation
import Foundation

/// Coğrafi hesaplama yardımcıları.
enum GeoUtils {
    private static let earthRadiusKm = 6371.0

    /// Haversine formülü ile iki koordinat arası mesafeyi kilometre cinsinden hesaplar.
    static func haversineDistance(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLat = (to.latitude - from.latitude) * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }

    /// Türkçe karakterleri normalize ederek karşılaştırma için hazırlar.
    static func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// İki yer adının eşleşip eşleşmediğini kontrol eder.
    static func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
        let left = normalize(lhs)
        let right = normalize(rhs)
        return left == right || left.contains(right) || right.contains(left)
    }

    /// Bir noktanın fay hattı segmentine en yakın mesafesini km cinsinden hesaplar.
    static func distanceToSegment(
        point: CLLocationCoordinate2D,
        segmentStart: CLLocationCoordinate2D,
        segmentEnd: CLLocationCoordinate2D,
        samples: Int = 20
    ) -> Double {
        var minDistance = haversineDistance(from: point, to: segmentStart)
        minDistance = min(minDistance, haversineDistance(from: point, to: segmentEnd))

        guard samples > 1 else { return minDistance }

        for index in 1..<samples {
            let fraction = Double(index) / Double(samples - 1)
            let lat = segmentStart.latitude + (segmentEnd.latitude - segmentStart.latitude) * fraction
            let lon = segmentStart.longitude + (segmentEnd.longitude - segmentStart.longitude) * fraction
            let sample = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            minDistance = min(minDistance, haversineDistance(from: point, to: sample))
        }
        return minDistance
    }
}
