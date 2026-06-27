// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import GoogleMobileAds
import UIKit

/// Google AdMob — banner, geçiş, ödüllü ve yerel gelişmiş reklamlar.
@MainActor
final class AdMobService: NSObject, ObservableObject {
    static let shared = AdMobService()

    @Published private(set) var isRewardedReady = false
    @Published private(set) var isInterstitialReady = false
    @Published private(set) var isShowingAd = false

    private var rewardedAd: GADRewardedAd?
    private var interstitialAd: GADInterstitialAd?
    private var isSDKStarted = false

    private var rewardedAdUnitID: String { AppConfiguration.rewardedAdUnitID }
    private var interstitialAdUnitID: String { AppConfiguration.interstitialAdUnitID }

    private override init() {
        super.init()
    }

    /// AdMob SDK'yı güvenli şekilde başlatır.
    func ensureSDKStarted() {
        guard !isSDKStarted else { return }
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              !appID.isEmpty,
              appID.contains("~") else {
            return
        }
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        isSDKStarted = true
    }

    /// Tüm reklam türlerini önceden yükler.
    func preloadAds() async {
        await loadRewardedAd()
        await loadInterstitialAd()
    }

    // MARK: - Ödüllü

    func loadRewardedAd() async {
        ensureSDKStarted()
        guard isSDKStarted else { return }

        do {
            rewardedAd = try await GADRewardedAd.load(withAdUnitID: rewardedAdUnitID, request: GADRequest())
            rewardedAd?.fullScreenContentDelegate = self
            isRewardedReady = rewardedAd != nil
        } catch {
            isRewardedReady = false
            rewardedAd = nil
        }
    }

    func showRewardedAd() async -> Bool {
        ensureSDKStarted()
        guard isSDKStarted else { return false }

        guard let rewardedAd, let rootVC = rootViewController else {
            await loadRewardedAd()
            return false
        }

        isShowingAd = true

        return await withCheckedContinuation { continuation in
            rewardedAd.present(fromRootViewController: rootVC) {
                continuation.resume(returning: true)
            }
            self.isShowingAd = false
            self.isRewardedReady = false
            Task { await self.loadRewardedAd() }
        }
    }

    // MARK: - Geçiş (Interstitial)

    func loadInterstitialAd() async {
        ensureSDKStarted()
        guard isSDKStarted else { return }

        do {
            interstitialAd = try await GADInterstitialAd.load(
                withAdUnitID: interstitialAdUnitID,
                request: GADRequest()
            )
            interstitialAd?.fullScreenContentDelegate = self
            isInterstitialReady = interstitialAd != nil
        } catch {
            isInterstitialReady = false
            interstitialAd = nil
        }
    }

    /// Geçiş reklamını gösterir; başarılıysa `true`.
    @discardableResult
    func showInterstitialAd() async -> Bool {
        ensureSDKStarted()
        guard isSDKStarted, !isShowingAd else { return false }

        guard let interstitialAd, let rootVC = rootViewController else {
            await loadInterstitialAd()
            return false
        }

        isShowingAd = true
        interstitialAd.present(fromRootViewController: rootVC)
        return true
    }

    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostViewController()
    }
}

extension AdMobService: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            isShowingAd = false
            if ad is GADRewardedAd {
                await loadRewardedAd()
            } else if ad is GADInterstitialAd {
                isInterstitialReady = false
                interstitialAd = nil
                await loadInterstitialAd()
            }
        }
    }

    nonisolated func ad(
        _ ad: GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            isShowingAd = false
            if ad is GADRewardedAd {
                isRewardedReady = false
            } else if ad is GADInterstitialAd {
                isInterstitialReady = false
                interstitialAd = nil
            }
        }
    }
}

private extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let navigation = self as? UINavigationController, let visible = navigation.visibleViewController {
            return visible.topMostViewController()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController()
        }
        return self
    }
}
