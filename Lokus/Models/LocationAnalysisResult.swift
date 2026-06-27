// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import Foundation

/// Backend `/api/query` yanıt kök modeli.
struct LocationAnalysisResult: Codable, Equatable {
    let parcel: GeoParcelInfo?
    let zoning: GeoZoningInfo?
    let infrastructure: GeoInfrastructureData
    let poi: GeoPOIData
    let dataSources: [GeoDataSource]
    let cached: Bool?

    enum CodingKeys: String, CodingKey {
        case parcel, zoning, infrastructure, poi
        case dataSources = "data_sources"
        case cached
    }
}

struct GeoParcelInfo: Codable, Equatable {
    let ada: String?
    let parsel: String?
    let yuzolcum: Double?
    let malikOzet: String?
    let il: String?
    let ilce: String?
    let mahalle: String?
    let confidenceLevel: GeoConfidenceLevel?

    enum CodingKeys: String, CodingKey {
        case ada, parsel, yuzolcum, il, ilce, mahalle
        case malikOzet = "malik_ozet"
        case confidenceLevel = "confidence_level"
    }
}

struct GeoZoningInfo: Codable, Equatable {
    let planNotu: String?
    let taks: Double?
    let kaks: Double?
    let yapilasmaTuru: String?
    let maxKat: String?
    let sonGuncelleme: String?
    let confidenceLevel: GeoConfidenceLevel?

    enum CodingKeys: String, CodingKey {
        case taks, kaks
        case planNotu = "plan_notu"
        case yapilasmaTuru = "yapilasma_turu"
        case maxKat = "max_kat"
        case sonGuncelleme = "son_guncelleme"
        case confidenceLevel = "confidence_level"
    }
}

struct GeoInfrastructureData: Codable, Equatable {
    let yol: Bool
    let su: Bool
    let elektrik: Bool
    let dogalgaz: Bool
    let fiber: Bool
    let topluTasima: Bool

    enum CodingKeys: String, CodingKey {
        case yol, su, elektrik, dogalgaz, fiber
        case topluTasima = "toplu_tasima"
    }
}

struct GeoPOIData: Codable, Equatable {
    let okullar: [GeoPOIItem]
    let hastaneler: [GeoPOIItem]
    let marketler: [GeoPOIItem]
    let parklar: [GeoPOIItem]
    let duraklar: [GeoPOIItem]
}

struct GeoPOIItem: Codable, Equatable, Identifiable {
    var id: String { "\(name)-\(distanceM)" }
    let name: String
    let category: String
    let distanceM: Int
    let lat: Double
    let lng: Double

    enum CodingKeys: String, CodingKey {
        case name, category, lat, lng
        case distanceM = "distance_m"
    }
}

struct GeoDataSource: Codable, Equatable, Identifiable {
    var id: String { "\(katman)-\(kaynak)" }
    let katman: String
    let kaynak: String
    let guncellemeTarihi: String
    let lisans: String?

    enum CodingKeys: String, CodingKey {
        case katman, kaynak, lisans
        case guncellemeTarihi = "guncelleme_tarihi"
    }
}

enum GeoConfidenceLevel: String, Codable {
    case high, medium, low

    var label: String {
        switch self {
        case .high: "Yüksek güven"
        case .medium: "Orta güven"
        case .low: "Düşük güven — resmi kaynağı doğrulayın"
        }
    }
}

enum MapOverlayType: String, CaseIterable, Identifiable {
    case zoning
    case parcels
    case infrastructure
    case faultLines

    var id: String { rawValue }

    var title: String {
        switch self {
        case .zoning: "İmar"
        case .parcels: "Parsel"
        case .infrastructure: "Altyapı"
        case .faultLines: "Fay Hatları"
        }
    }

    var icon: String {
        switch self {
        case .zoning: "building.2"
        case .parcels: "square.grid.3x3"
        case .infrastructure: "bolt"
        case .faultLines: "waveform.path.ecg"
        }
    }

    var subtitle: String {
        switch self {
        case .zoning: "İmar planı poligonları"
        case .parcels: "Ada / parsel sınırları"
        case .infrastructure: "Yol, su, enerji hatları"
        case .faultLines: "Aktif fay hatları (Lokus verisi)"
        }
    }
}
