// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import CoreLocation
import Foundation

/// CLGeocoder ile konum çözümleme ve JSON eşleştirme servisi.
@MainActor
final class LocationAnalyzer: ObservableObject {
    private let geocoder = CLGeocoder()

    /// Koordinatı il/ilçe/mahalle bilgisine çevirir.
    func resolveLocation(_ coordinate: CLLocationCoordinate2D) async throws -> LocationResult {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.reverseGeocodeLocation(location)
        } catch {
            throw LokusError.geocodingFailed
        }

        guard let placemark = placemarks.first else {
            throw LokusError.geocodingFailed
        }

        let provinceName = placemark.administrativeArea ?? placemark.locality ?? "Bilinmiyor"
        let districtName = placemark.subAdministrativeArea ?? placemark.locality ?? provinceName
        let villageName = placemark.subLocality
            ?? placemark.thoroughfare
            ?? placemark.name
            ?? districtName

        let formattedAddress = [
            placemark.thoroughfare,
            placemark.subLocality,
            placemark.subAdministrativeArea,
            placemark.administrativeArea
        ]
        .compactMap { $0 }
        .joined(separator: ", ")

        return LocationResult(
            coordinate: coordinate,
            provinceName: provinceName,
            districtName: districtName,
            villageName: villageName,
            formattedAddress: formattedAddress.isEmpty ? provinceName : formattedAddress
        )
    }

    /// Geocoder sonucunu JSON verisiyle eşleştirir; bulunamazsa en yakın ilçe köyünü döner.
    func findNearestVillage(for result: LocationResult, in provinces: [Province]) -> Village? {
        if let exact = matchVillage(in: provinces, result: result) {
            return exact
        }

        if let province = provinces.first(where: { GeoUtils.namesMatch($0.name, result.provinceName) }) {
            if let district = province.districts.first(where: { GeoUtils.namesMatch($0.name, result.districtName) }) {
                return district.villages.first
            }
            return province.districts.first?.villages.first
        }

        return provinces.first?.districts.first?.villages.first
    }

    /// Geocoder sonucundan eşleşen il plaka numarasını bulur.
    func matchingPlateNumber(for result: LocationResult, in summaries: [Province]) -> Int? {
        summaries.first(where: { GeoUtils.namesMatch($0.name, result.provinceName) })?.plateNumber
    }

    /// Haversine formülü ile iki koordinat arası mesafeyi km cinsinden hesaplar.
    func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        GeoUtils.haversineDistance(from: from, to: to)
    }

    private func matchVillage(in provinces: [Province], result: LocationResult) -> Village? {
        for province in provinces where GeoUtils.namesMatch(province.name, result.provinceName) {
            for district in province.districts where GeoUtils.namesMatch(district.name, result.districtName) {
                if let village = district.villages.first(where: {
                    GeoUtils.namesMatch($0.name, result.villageName)
                }) {
                    return village
                }
                return district.villages.first
            }
        }
        return nil
    }
}

/// Reverse geocoding sonucu.
struct LocationResult {
    let coordinate: CLLocationCoordinate2D
    let provinceName: String
    let districtName: String
    let villageName: String
    let formattedAddress: String
}
