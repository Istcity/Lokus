// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import GoogleMobileAds
import SwiftUI
import UIKit

/// AdMob banner — 320×50 standart.
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        AdMobService.shared.ensureSDKStarted()
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.rootViewController = rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
        if uiView.rootViewController == nil {
            uiView.rootViewController = rootViewController
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    final class Coordinator: NSObject, GADBannerViewDelegate {}
}

/// Premium olmayan kullanıcılar için alt banner şeridi.
struct AdBannerStrip: View {
    @ObservedObject private var revenueCat = RevenueCatService.shared

    var body: some View {
        Group {
            if !revenueCat.hasPremiumAccess {
                BannerAdView(adUnitID: AppConfiguration.bannerAdUnitID)
                    .frame(height: GADAdSizeBanner.size.height)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
            }
        }
    }
}

extension View {
    /// Tab bar üstünde ince banner — Premium'da gizlenir.
    func lokusAdBanner() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            AdBannerStrip()
        }
    }
}
