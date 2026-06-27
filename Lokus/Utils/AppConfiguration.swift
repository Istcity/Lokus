// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Uygulama yapılandırması ve gizli anahtar yönetimi.
enum AppConfiguration {
    private static let secretsFileName = "Secrets"

    /// RevenueCat public API anahtarı (`Secrets.plist` veya varsayılan placeholder).
    static var revenueCatAPIKey: String {
        string(forKey: "REVENUECAT_API_KEY") ?? Constants.revenueCatAPIKey
    }

    /// RevenueCat entitlement kimliği.
    static var premiumEntitlementID: String {
        string(forKey: "REVENUECAT_ENTITLEMENT_ID") ?? Constants.premiumEntitlementID
    }

    /// AdMob uygulama kimliği (`GADApplicationIdentifier`).
    static var adMobApplicationID: String {
        string(forKey: "ADMOB_APPLICATION_ID") ?? AdMobIDs.application
    }

    /// AdMob banner reklam birim kimliği.
    static var bannerAdUnitID: String {
        string(forKey: "ADMOB_BANNER_AD_UNIT_ID") ?? AdMobIDs.banner
    }

    /// AdMob geçiş (interstitial) reklam birim kimliği.
    static var interstitialAdUnitID: String {
        string(forKey: "ADMOB_INTERSTITIAL_AD_UNIT_ID") ?? AdMobIDs.interstitial
    }

    /// AdMob ödüllü reklam birim kimliği.
    static var rewardedAdUnitID: String {
        string(forKey: "ADMOB_REWARDED_AD_UNIT_ID") ?? AdMobIDs.rewarded
    }

    /// AdMob yerel gelişmiş reklam birim kimliği.
    static var nativeAdvancedAdUnitID: String {
        string(forKey: "ADMOB_NATIVE_ADVANCED_AD_UNIT_ID") ?? AdMobIDs.nativeAdvanced
    }

    /// Test aşamasında premium + reklam kapılarını atla (`Secrets.plist` → TEST_BYPASS_PREMIUM).
    static var testBypassPremium: Bool {
        guard let raw = stringRaw(forKey: "TEST_BYPASS_PREMIUM") else {
            return true
        }
        return raw == "1" || raw.lowercased() == "true" || raw.lowercased() == "yes"
    }

    /// Premium ürün kimliği (App Store Connect Product ID).
    static var premiumProductID: String {
        string(forKey: "PREMIUM_PRODUCT_ID") ?? Constants.premiumProductID
    }

    /// RevenueCat API anahtarı gerçek bir değerle yapılandırılmış mı?
    static var isRevenueCatConfigured: Bool {
        let key = revenueCatAPIKey
        return !key.isEmpty
            && key != Constants.revenueCatAPIKey
            && !key.hasPrefix("YOUR_")
            && key.hasPrefix("appl_")
    }

    /// Lokus Geo Backend URL (FastAPI).
    static var geoBackendURL: URL? {
        guard let raw = string(forKey: Constants.geoBackendURLKey),
              let url = URL(string: raw) else {
            return nil
        }
        return url
    }

    /// Geo backend yapılandırılmış mı?
    static var isGeoBackendConfigured: Bool {
        geoBackendURL != nil
    }

    /// Yasal veri kaynağı attribution metni.
    static let geoAttributionText =
        "Parsel ve imar verileri TKGM, ilgili belediyeler ve Çevre Bakanlığı açık veri kaynaklarından derlenmektedir. Bilgilerin güncelliği ve doğruluğu için resmi kaynaklara başvurunuz."

    private static func string(forKey key: String) -> String? {
        guard let url = Bundle.main.url(forResource: secretsFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist[key] as? String,
              !value.isEmpty,
              !value.hasPrefix("YOUR_") else {
            return nil
        }
        return value
    }

    /// Boolean plist değeri (TEST_BYPASS_PREMIUM vb.).
    fileprivate static func stringRaw(forKey key: String) -> String? {
        guard let url = Bundle.main.url(forResource: secretsFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist[key] as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }
}
