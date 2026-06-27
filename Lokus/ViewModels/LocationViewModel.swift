// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import CoreLocation
import Foundation

/// Uygulama genelinde paylaşılan konum durumu.
@MainActor
final class LocationViewModel: ObservableObject {
    static let shared = LocationViewModel()

    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var formattedAddress: String = ""
    @Published var provinceName: String = ""
    @Published var districtName: String = ""

    private init() {}

    /// Harita veya geocoder sonucundan konum bilgisini günceller.
    func update(from result: LocationResult) {
        selectedCoordinate = result.coordinate
        formattedAddress = result.formattedAddress
        provinceName = result.provinceName
        districtName = result.districtName
    }

    /// Koordinat ve adres bilgisini manuel ayarlar.
    func update(coordinate: CLLocationCoordinate2D, address: String) {
        selectedCoordinate = coordinate
        formattedAddress = address
    }
}
