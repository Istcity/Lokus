// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Yerleşim verisinin kaynağı.
enum SettlementDataSource: String, Codable {
    case localIndex = "Yerel İndeks"
    case apiVerified = "TurkiyeAPI"
    case estimated = "Tahmini Model"
    case hybrid = "Karma (API + Tahmin)"
}

/// Çözümlenmiş yerleşim — mahalle veya köy.
struct ResolvedSettlement: Identifiable, Hashable {
    var id: String { "\(provinceName)-\(districtName)-\(settlementName)" }
    let village: Village
    let provinceName: String
    let districtName: String
    let settlementName: String
    let districtId: Int
    let provincePlate: Int
    let dataSource: SettlementDataSource
    let officialPopulation: Int?
    let isNeighborhood: Bool
}
