// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Tüm finansal hesaplamalar — on-device, sıfır API çağrısı.
enum ROIFormulas {
    /// Toplam inşaat maliyetini hesaplar.
    static func totalBuildingCost(grossM2: Double, costPerM2: Double) -> Double {
        grossM2 * costPerM2
    }

    /// KAKS'a göre inşaat edilebilir brüt alanı hesaplar.
    static func buildableArea(landM2: Double, kaks: Double) -> Double {
        landM2 * kaks
    }

    /// Brüt kâr ve kâr marjını hesaplar.
    static func profitAndMargin(revenue: Double, totalCost: Double) -> (profit: Double, margin: Double) {
        let profit = revenue - totalCost
        let margin = revenue > 0 ? (profit / revenue) * 100 : 0
        return (profit, margin)
    }

    /// Başa baş satış fiyatını m² başına hesaplar.
    static func breakEvenPrice(totalCost: Double, totalM2: Double) -> Double {
        guard totalM2 > 0 else { return 0 }
        return totalCost / totalM2
    }

    /// 5 yıllık değer artışı projeksiyonu (yıllık büyüme oranı %).
    static func fiveYearProjection(currentValue: Double, annualGrowthRate: Double) -> [Double] {
        (0...5).map { year in
            currentValue * pow(1 + annualGrowthRate / 100, Double(year))
        }
    }

    /// Yıllık kira getirisi yüzdesini hesaplar.
    static func rentalYield(monthlyRent: Double, totalInvestment: Double) -> Double {
        guard totalInvestment > 0 else { return 0 }
        return (monthlyRent * 12 / totalInvestment) * 100
    }

    /// Tam fizibilite analizi sonucunu üretir.
    static func calculate(input: ROIInput, annualGrowthRate: Double, monthlyRent: Double) -> ROIResult {
        let landCost = input.landAreaM2 * input.landPricePerM2
        let constructionCost = totalBuildingCost(grossM2: input.grossFloorArea, costPerM2: input.constructionCostPerM2)
        let totalCost = landCost + constructionCost
        let revenue = input.grossFloorArea * input.salePricePerM2
        let (profit, margin) = profitAndMargin(revenue: revenue, totalCost: totalCost)
        let breakEven = breakEvenPrice(totalCost: totalCost, totalM2: input.grossFloorArea)
        let yieldPercent = rentalYield(monthlyRent: monthlyRent, totalInvestment: totalCost)
        let annualRent = monthlyRent * 12
        let payback = annualRent > 0 ? totalCost / annualRent : 0
        let projection = fiveYearProjection(currentValue: totalCost, annualGrowthRate: annualGrowthRate)

        return ROIResult(
            totalLandCost: landCost,
            totalConstructionCost: constructionCost,
            totalCost: totalCost,
            totalRevenue: revenue,
            grossProfit: profit,
            profitMargin: margin,
            breakEvenM2: breakEven,
            paybackYears: payback,
            rentalYieldPercent: yieldPercent,
            fiveYearProjection: projection
        )
    }
}
