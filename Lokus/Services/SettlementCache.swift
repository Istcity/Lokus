// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Çevrimiçi yerleşim sorgu önbelleği.
actor SettlementCache {
    static let shared = SettlementCache()

    private var memory: [String: APISettlement] = [:]
    private let fileURL: URL

    private init() {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        fileURL = directory.appendingPathComponent("lokus_settlement_cache.json")
        loadFromDisk()
    }

    func get(key: String) -> APISettlement? {
        memory[key]
    }

    func set(key: String, settlement: APISettlement) {
        memory[key] = settlement
        saveToDisk()
    }

    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: APISettlement].self, from: data) else {
            return
        }
        memory = decoded
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(memory) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
