// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import SwiftUI

/// Deprem/yatırım risk seviyesi rozeti.
struct RiskBadgeView: View {
    let level: RiskLevel

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
            Text(level.rawValue)
                .font(.subheadline.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(badgeColor, in: Capsule())
    }

    private var badgeColor: Color {
        switch level {
        case .low: return Color("SuccessGreen")
        case .medium: return Color("WarningAmber")
        case .high: return Color("DangerRed")
        }
    }

    private var iconName: String {
        switch level {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        RiskBadgeView(level: .low)
        RiskBadgeView(level: .medium)
        RiskBadgeView(level: .high)
    }
}
