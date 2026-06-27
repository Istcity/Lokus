// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Bölgesel özet JSON kök modeli (hafif — sadece il düzeyi).
struct RegionalSummary: Codable {
    let version: String
    let lastUpdated: String
    let provinces: [Province]
}

/// Tam idari indeks kök modeli (81 il + 973 ilçe).
struct AdministrativeIndex: Codable {
    let version: String
    let source: String
    let lastUpdated: String
    let provinceCount: Int
    let districtCount: Int
    let provinces: [ProvinceIndex]
}

/// İl düzeyinde idari ve fiyat indeksi.
struct ProvinceIndex: Codable, Identifiable, Hashable {
    var id: Int { plateNumber }
    let plateNumber: Int
    let name: String
    let avgHousePrice: Double
    let population: Int?
    let isMetropolitan: Bool?
    let districts: [DistrictIndex]
}

/// İlçe düzeyinde idari meta veri.
struct DistrictIndex: Codable, Identifiable, Hashable {
    var id: Int { apiId }
    let apiId: Int
    let name: String
    let population: Int?
    let neighborhoodCount: Int?
    let villageCount: Int?
    let areaKm2: Double?

    enum CodingKeys: String, CodingKey {
        case apiId = "id"
        case name, population, neighborhoodCount, villageCount, areaKm2
    }
}

/// İl düzeyinde bölge verisi.
struct Province: Codable, Identifiable, Hashable {
    var id: Int { plateNumber }
    let plateNumber: Int
    let name: String
    let avgHousePrice: Double
    let districts: [District]
}

/// İlçe düzeyinde bölge verisi.
struct District: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let villages: [Village]
}

/// Köy/mahalle düzeyinde detaylı gayrimenkul verisi.
struct Village: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let housePricePerM2: Double
    let landPricePerM2: Double
    let zoning: ZoningInfo
    let infrastructure: Infrastructure
    let notes: String
}

/// İmar bilgileri.
struct ZoningInfo: Codable, Hashable {
    let taks: Double
    let kaks: Double
    let maxFloors: String
    let status: ZoningStatus
}

/// İmar durumu kategorileri.
enum ZoningStatus: String, Codable, Hashable {
    case residential = "Konut"
    case agricultural = "Tarım"
    case commercial = "Ticari"
    case undeveloped = "İmarsız"
}

/// Altyapı durumu.
struct Infrastructure: Codable, Hashable {
    let electricity: Bool
    let water: Bool
    let naturalGas: Bool
    let road: Bool
    let internet: Bool
}
