// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// On-Demand Resources ile il bazlı detay JSON indirme yöneticisi.
final class ODRManager {
    static let shared = ODRManager()

    private let adminStore = AdministrativeDataStore.shared
    private var activeRequests: [Int: NSBundleResourceRequest] = [:]
    private var downloadedProvinces: Set<Int> = []
    private var provinceCache: [Int: ProvinceIndex] = [:]

    private init() {}

    /// Belirtilen plaka numaralı ilin tam idari kaydını döndürür.
    func requestProvince(plateNumber: Int) async throws -> ProvinceIndex {
        if let cached = provinceCache[plateNumber] {
            return cached
        }

        if let province = try adminStore.province(plateNumber: plateNumber) {
            cacheProvince(province)
            return province
        }

        let tag = provinceTag(for: plateNumber)
        let request = NSBundleResourceRequest(tags: [tag])
        activeRequests[plateNumber] = request

        do {
            try await request.beginAccessingResources()
            if let province = try adminStore.province(plateNumber: plateNumber) {
                cacheProvince(province)
                return province
            }
            throw LokusError.odrDownloadFailed(plateNumber)
        } catch {
            throw LokusError.odrDownloadFailed(plateNumber)
        }
    }

    /// İl verisinin yüklenip yüklenmediğini kontrol eder.
    func isProvinceDownloaded(plateNumber: Int) -> Bool {
        provinceCache[plateNumber] != nil
            || downloadedProvinces.contains(plateNumber)
            || (try? adminStore.province(plateNumber: plateNumber)) != nil
    }

    /// Tüm aktif ODR isteklerini iptal eder.
    func cancelAllRequests() {
        for (_, request) in activeRequests {
            request.endAccessingResources()
        }
        activeRequests.removeAll()
    }

    private func cacheProvince(_ province: ProvinceIndex) {
        provinceCache[province.plateNumber] = province
        downloadedProvinces.insert(province.plateNumber)
    }

    private func provinceTag(for plateNumber: Int) -> String {
        "province_\(String(format: "%02d", plateNumber))"
    }
}
