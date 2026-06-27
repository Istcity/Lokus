// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import SwiftUI

extension ZoningInfo {
    /// Taban Alan Kat Sayısı kısaltması açılımı.
    static let taksFullName = "Taban Alan Kat Sayısı"

    /// Kat Alanları Kat Sayısı kısaltması açılımı.
    static let kaksFullName = "Kat Alanları Kat Sayısı"

    var statusColor: Color {
        switch status {
        case .residential: Color("AccentOrange")
        case .commercial: Color("WarningAmber")
        case .agricultural: Color("SuccessGreen")
        case .undeveloped: Color("TextSecondary")
        }
    }

    var statusIcon: String {
        switch status {
        case .residential: "building.2.fill"
        case .commercial: "storefront.fill"
        case .agricultural: "leaf.fill"
        case .undeveloped: "map.fill"
        }
    }
}
