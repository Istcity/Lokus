// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// 81 il + 973 ilçe idari indeksini yükler ve sorgular.
final class AdministrativeDataStore {
    static let shared = AdministrativeDataStore()

    private var cachedIndex: AdministrativeIndex?

    private init() {}

    /// Tam idari indeksi yükler.
    func loadIndex() throws -> AdministrativeIndex {
        if let cachedIndex { return cachedIndex }

        guard let url = Bundle.main.url(
            forResource: Constants.administrativeIndexFileName,
            withExtension: "json"
        ) else {
            throw LokusError.regionDataNotFound
        }

        let data = try Data(contentsOf: url)
        let index = try JSONDecoder().decode(AdministrativeIndex.self, from: data)
        cachedIndex = index
        return index
    }

    /// İl adına göre il kaydını bulur.
    func province(matching name: String) throws -> ProvinceIndex? {
        try loadIndex().provinces.first { GeoUtils.namesMatch($0.name, name) }
    }

    /// İl plakasına göre il kaydını bulur.
    func province(plateNumber: Int) throws -> ProvinceIndex? {
        try loadIndex().provinces.first { $0.plateNumber == plateNumber }
    }

    /// İl ve ilçe adına göre ilçe kaydını bulur.
    func district(provinceName: String, districtName: String) throws -> (ProvinceIndex, DistrictIndex)? {
        guard let province = try province(matching: provinceName) else { return nil }
        guard let district = province.districts.first(where: { GeoUtils.namesMatch($0.name, districtName) }) else {
            return nil
        }
        return (province, district)
    }
}
