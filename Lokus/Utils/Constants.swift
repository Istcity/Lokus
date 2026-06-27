// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Uygulama genelinde kullanılan sabitler.
enum Constants {
    static let bundleID = "com.sinannergiz.lokus"
    static let appGroupID = "group.com.sinannergiz.shared"
    static let premiumProductID = "lokus_premium_annual"
    static let premiumEntitlementID = "premium"
    static let revenueCatOfferingID = "default"
    static let unlockDurationHours: TimeInterval = 2
    static let lastUnlockTimestampKey = "lastUnlockTimestamp"
    static let regionalSummaryFileName = "regional_summary"
    static let administrativeIndexFileName = "administrative_index"
    static let turkiyeAPIBaseURL = "https://api.turkiyeapi.dev/v2"
    static let revenueCatAPIKey = "REVENUECAT_PUBLIC_KEY"
    static let geoBackendURLKey = "GEO_BACKEND_URL"
    /// Şantiye Asist App Store arama bağlantısı (partner uygulama).
    static let santiyeAsistAppStoreURL = "https://apps.apple.com/tr/search?term=Santiye+Asist+Sinan+Nergiz"
    /// Şantiye Asist özel URL şeması (yüklüyse açılır).
    static let santiyeAsistURLScheme = "santiyek://"
}

/// Lokus uygulaması hata türleri.
enum LokusError: LocalizedError {
    case locationDenied
    case geocodingFailed
    case regionDataNotFound
    case odrDownloadFailed(Int)
    case santiyeAsistNotInstalled
    case premiumRequired
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .locationDenied:
            return "Konum izni gerekli. Ayarlar > Lokus > Konum'u etkinleştirin."
        case .geocodingFailed:
            return "Konum çözümlenemedi. İnternet bağlantınızı kontrol edin."
        case .regionDataNotFound:
            return "Bu bölge için henüz veri bulunmuyor."
        case .odrDownloadFailed(let plate):
            return "\(plate) plakalı il verisi indirilemedi."
        case .santiyeAsistNotInstalled:
            return "Şantiye Asist uygulaması yüklü değil veya henüz veri paylaşılmamış."
        case .premiumRequired:
            return "Bu özellik için Lokus Premium gerekli."
        case .networkUnavailable:
            return "Çevrimiçi yerleşim verisi alınamadı. Tahmini veriler gösteriliyor."
        }
    }
}
