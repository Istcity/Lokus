// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Lokus marka logosu — şeffaf asset + cam kapsül arka plan.
struct LokusBrandView: View {
    enum Style {
        case hero
        case header
        case toolbar
        case compact

        var logoHeight: CGFloat {
            switch self {
            case .hero: 112
            case .header: 56
            case .toolbar: 26
            case .compact: 18
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .hero: 28
            case .header: 18
            case .toolbar: 12
            case .compact: 8
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .hero: 16
            case .header: 10
            case .toolbar: 6
            case .compact: 4
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .hero: 24
            case .header: 18
            case .toolbar: 12
            case .compact: 8
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .hero: 12
            case .header: 8
            case .toolbar: 4
            case .compact: 2
            }
        }
    }

    var style: Style = .header

    var body: some View {
        Image("LokusLogo")
            .resizable()
            .scaledToFit()
            .frame(height: style.logoHeight)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, style.verticalPadding)
            .background { glassBackground }
            .accessibilityLabel("Lokus")
    }

    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: style.shadowRadius, y: 2)
    }
}

/// Navigation bar için ortalanmış cam logo başlığı.
struct LokusNavigationTitle: View {
    var style: LokusBrandView.Style = .toolbar

    var body: some View {
        LokusBrandView(style: style)
    }
}

extension View {
    /// Ana sekme navigation bar'ına cam Lokus logosu ekler.
    func lokusNavigationBarLogo(style: LokusBrandView.Style = .toolbar) -> some View {
        toolbar {
            ToolbarItem(placement: .principal) {
                LokusNavigationTitle(style: style)
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color("PrimaryNavy"), Color("AccentOrange").opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 24) {
            LokusBrandView(style: .hero)
            LokusBrandView(style: .header)
            LokusBrandView(style: .toolbar)
            LokusBrandView(style: .compact)
        }
        .padding()
    }
}
