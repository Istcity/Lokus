// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import Foundation

/// Premium erişim — test bypass ve RevenueCat birleşimi.
enum PremiumAccess {
    /// TestFlight / geliştirme: tüm premium özellikler açık, reklam kapısı yok.
    static var bypassEnabled: Bool {
        if AppConfiguration.testBypassPremium { return true }
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static func hasPremium(isSubscribed: Bool) -> Bool {
        bypassEnabled || isSubscribed
    }

    static func hasFeatureAccess(isSubscribed: Bool, unlockedByAd: Bool) -> Bool {
        bypassEnabled || isSubscribed || unlockedByAd
    }
}
