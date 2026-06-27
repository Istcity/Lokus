// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import Foundation

/// İlçe bazlı fiyat kalibrasyon çarpanları.
struct DistrictPriceCalibration: Codable {
    let version: String
    let lastUpdated: String
    let factors: [String: Double]
}

/// `district_price_factors.json` dosyasından kalibrasyon yükler.
enum PriceCalibrationStore {
    private static var cached: DistrictPriceCalibration?

    static func load() -> DistrictPriceCalibration? {
        if let cached { return cached }
        guard let url = Bundle.main.url(forResource: "district_price_factors", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let calibration = try? JSONDecoder().decode(DistrictPriceCalibration.self, from: data) else {
            return nil
        }
        cached = calibration
        return calibration
    }

    /// İlçe API kimliği için fiyat çarpanı (varsayılan 1.0).
    static func factor(forDistrictId districtId: Int) -> Double {
        guard let calibration = load() else { return 1.0 }
        return calibration.factors[String(districtId)] ?? 1.0
    }

    /// İl plaka numarası için ortalama fiyat kalibrasyonu.
    static func provincePrice(from regionalAvg: Double, plateNumber: Int) -> Double {
        guard let summary = try? DataLoader().loadRegionalSummary() else { return regionalAvg }
        guard let province = summary.provinces.first(where: { $0.plateNumber == plateNumber }) else {
            return regionalAvg
        }
        if regionalAvg <= 0 { return province.avgHousePrice }
        let blend = 0.35
        return regionalAvg * (1 - blend) + province.avgHousePrice * blend
    }
}
