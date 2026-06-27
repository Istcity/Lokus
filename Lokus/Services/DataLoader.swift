// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Yerel JSON veri dosyalarını yükleyen servis.
final class DataLoader {
    private var cachedSummary: RegionalSummary?

    /// `regional_summary.json` dosyasını bundle'dan yükler.
    func loadRegionalSummary() throws -> RegionalSummary {
        if let cachedSummary {
            return cachedSummary
        }

        guard let url = Bundle.main.url(
            forResource: Constants.regionalSummaryFileName,
            withExtension: "json"
        ) else {
            throw LokusError.regionDataNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let summary = try decoder.decode(RegionalSummary.self, from: data)
        cachedSummary = summary
        return summary
    }

    /// Tüm il özetlerini döndürür (detaylı ilçe/köy verisi ODR'da).
    func loadProvinces() throws -> [Province] {
        try loadRegionalSummary().provinces
    }

    /// Bundle'dan il detay JSON dosyasını yükler.
    func loadProvinceDetail(plateNumber: Int) throws -> Province {
        let fileName = "province_\(String(format: "%02d", plateNumber))"
        let subdirectories = ["Provinces", "Data/Provinces", nil] as [String?]

        for subdirectory in subdirectories {
            if let url = Bundle.main.url(
                forResource: fileName,
                withExtension: "json",
                subdirectory: subdirectory
            ) {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(Province.self, from: data)
            }
        }

        throw LokusError.odrDownloadFailed(plateNumber)
    }

    /// `fault_lines.json` dosyasını bundle'dan yükler.
    func loadFaultLines() throws -> [FaultLine] {
        guard let url = Bundle.main.url(forResource: "fault_lines", withExtension: "json") else {
            throw LokusError.regionDataNotFound
        }
        let data = try Data(contentsOf: url)
        let collection = try JSONDecoder().decode(FaultLineCollection.self, from: data)
        return collection.faultLines
    }
}
