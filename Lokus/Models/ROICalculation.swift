// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Maliyet kaynağı seçenekleri.
enum CostSource: String, CaseIterable, Identifiable {
    case santiyeAsist = "Şantiye Asist"
    case manual = "Manuel Giriş"
    case marketAvg = "Piyasa Ort."

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .santiyeAsist: "🔵 Şantiye Asist"
        case .manual: "🟡 Manuel Giriş"
        case .marketAvg: "⚪ Piyasa Ort."
        }
    }
}

/// Fizibilite hesaplama girdileri.
struct ROIInput {
    let landAreaM2: Double
    let landPricePerM2: Double
    let constructionCostPerM2: Double
    let grossFloorArea: Double
    let salePricePerM2: Double
}

/// Fizibilite hesaplama sonuçları.
struct ROIResult {
    let totalLandCost: Double
    let totalConstructionCost: Double
    let totalCost: Double
    let totalRevenue: Double
    let grossProfit: Double
    let profitMargin: Double
    let breakEvenM2: Double
    let paybackYears: Double
    let rentalYieldPercent: Double
    let fiveYearProjection: [Double]
}
