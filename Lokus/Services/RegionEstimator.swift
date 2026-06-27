// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import Foundation

/// İl/ilçe/yerleşim meta verisinden gayrimenkul profili türetir.
enum RegionEstimator {
    /// Tahmini köy/mahalle profili üretir.
    static func estimateVillage(
        settlementName: String,
        district: DistrictIndex,
        province: ProvinceIndex,
        population: Int? = nil,
        dataSource: SettlementDataSource,
        apiSettlementName: String? = nil,
        isSettlementNeighborhood: Bool = true
    ) -> Village {
        let districtMultiplier = priceMultiplier(for: district, in: province)
        let calibrationFactor = PriceCalibrationStore.factor(forDistrictId: district.apiId)
        let settlementFactor = settlementPriceFactor(
            name: settlementName,
            population: population,
            isNeighborhood: isSettlementNeighborhood
        )
        let blendedProvincePrice = PriceCalibrationStore.provincePrice(
            from: province.avgHousePrice,
            plateNumber: province.plateNumber
        )
        let housePrice = round(blendedProvincePrice * districtMultiplier * settlementFactor * calibrationFactor / 100) * 100
        let landPrice = round(housePrice * landRatio(for: district, isNeighborhood: isSettlementNeighborhood) / 100) * 100
        let zoning = zoningProfile(
            for: district,
            province: province,
            settlementName: settlementName,
            population: population,
            isNeighborhood: isSettlementNeighborhood
        )
        let infrastructure = infrastructureProfile(
            for: district,
            province: province,
            population: population,
            isNeighborhood: isSettlementNeighborhood
        )
        let displayName = apiSettlementName ?? settlementName

        let popText = population.map { "Nüfus: \($0.formatted()) · " } ?? ""
        let settlementType = isSettlementNeighborhood ? "Mahalle" : "Köy"
        let sourceNote: String
        switch dataSource {
        case .apiVerified:
            sourceNote = "Resmi yerleşim kaydı (TurkiyeAPI) ile doğrulandı."
        case .hybrid:
            sourceNote = "Konum + API verisi birleştirildi."
        case .localIndex:
            sourceNote = "İlçe indeksinden türetildi."
        case .estimated:
            sourceNote = "Geocoder + bölgesel model ile tahmin edildi."
        }

        let notes = "\(popText)\(settlementType) · \(district.name), \(province.name) — \(sourceNote) İmar ve fiyatlar tahminidir; resmi çap belgesi yerine geçmez."

        return Village(
            name: displayName,
            housePricePerM2: housePrice,
            landPricePerM2: landPrice,
            zoning: zoning,
            infrastructure: infrastructure,
            notes: notes
        )
    }

    private static func priceMultiplier(for district: DistrictIndex, in province: ProvinceIndex) -> Double {
        var multiplier = 1.0

        if province.isMetropolitan == true {
            multiplier += 0.15
        }

        if let population = district.population {
            let popFactor = min(log10(Double(max(population, 1_000))) / 5.5, 1.4)
            multiplier *= (0.75 + popFactor * 0.35)
        }

        if let area = district.areaKm2, area > 500, (district.population ?? 0) < 50_000 {
            multiplier *= 0.82
        }

        return min(max(multiplier, 0.55), 2.8)
    }

    private static func settlementPriceFactor(
        name: String,
        population: Int?,
        isNeighborhood: Bool
    ) -> Double {
        var factor = 1.0

        if let population {
            if population > 20_000 { factor += 0.12 }
            else if population > 8_000 { factor += 0.06 }
            else if population < 800 { factor -= 0.10 }
        }

        if !isNeighborhood {
            factor -= 0.08
        }

        let hash = abs(name.hashValue % 7)
        factor += Double(hash) * 0.015 - 0.045

        return min(max(factor, 0.75), 1.35)
    }

    private static func landRatio(for district: DistrictIndex, isNeighborhood: Bool) -> Double {
        if !isNeighborhood { return 0.38 }
        let isRural = (district.villageCount ?? 0) > (district.neighborhoodCount ?? 0)
        return isRural ? 0.45 : 0.58
    }

    private static func zoningProfile(
        for district: DistrictIndex,
        province: ProvinceIndex,
        settlementName: String,
        population: Int?,
        isNeighborhood: Bool
    ) -> ZoningInfo {
        let base = districtZoningBase(for: district, province: province)
        var taks = base.taks
        var kaks = base.kaks
        var status = base.status
        var maxFloorCount = base.floorCount

        if isNeighborhood {
            if (district.neighborhoodCount ?? 0) >= 8 {
                kaks = min(kaks + 0.15, 2.0)
                maxFloorCount = min(maxFloorCount + 1, 8)
            }
            if let pop = population, pop > 12_000 {
                status = .commercial
                kaks = min(kaks + 0.10, 2.2)
                taks = min(taks + 0.05, 0.45)
            }
        } else {
            status = .agricultural
            taks = min(taks, 0.28)
            kaks = min(kaks, 0.70)
            maxFloorCount = min(maxFloorCount, 2)
            if let pop = population, pop < 400 {
                status = .undeveloped
                taks = 0.15
                kaks = 0.30
                maxFloorCount = 1
            }
        }

        if province.isMetropolitan == true, isNeighborhood {
            kaks = min(kaks + 0.08, 2.4)
            maxFloorCount = min(maxFloorCount + 1, 10)
        }

        let nameVariation = Double(abs(settlementName.hashValue % 9)) * 0.02 - 0.08
        taks = min(max(taks + nameVariation, 0.10), 0.50)
        kaks = min(max(kaks + nameVariation * 1.5, 0.25), 2.5)
        maxFloorCount = max(1, min(maxFloorCount + (abs(settlementName.hashValue) % 3) - 1, 12))

        return ZoningInfo(
            taks: (taks * 100).rounded() / 100,
            kaks: (kaks * 100).rounded() / 100,
            maxFloors: "\(maxFloorCount) Kat",
            status: status
        )
    }

    private struct DistrictZoningBase {
        let taks: Double
        let kaks: Double
        let status: ZoningStatus
        let floorCount: Int
    }

    private static func districtZoningBase(for district: DistrictIndex, province: ProvinceIndex) -> DistrictZoningBase {
        let urban = (district.neighborhoodCount ?? 0) >= 5
        let ruralHeavy = (district.villageCount ?? 0) > 10
            && (district.neighborhoodCount ?? 0) < 3

        if province.isMetropolitan == true, urban {
            return DistrictZoningBase(taks: 0.35, kaks: 1.50, status: .residential, floorCount: 6)
        }
        if urban {
            return DistrictZoningBase(taks: 0.30, kaks: 1.20, status: .residential, floorCount: 5)
        }
        if ruralHeavy {
            return DistrictZoningBase(taks: 0.22, kaks: 0.55, status: .agricultural, floorCount: 2)
        }
        return DistrictZoningBase(taks: 0.32, kaks: 0.90, status: .residential, floorCount: 3)
    }

    private static func infrastructureProfile(
        for district: DistrictIndex,
        province: ProvinceIndex,
        population: Int?,
        isNeighborhood: Bool
    ) -> Infrastructure {
        let districtPop = district.population ?? 0
        let settlementPop = population ?? districtPop
        let urban = districtPop > 30_000 || province.isMetropolitan == true

        return Infrastructure(
            electricity: true,
            water: settlementPop > 200 || isNeighborhood,
            naturalGas: urban && isNeighborhood && settlementPop > 3_000,
            road: true,
            internet: urban || settlementPop > 1_500 || isNeighborhood
        )
    }
}
