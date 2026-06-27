// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// TurkiyeAPI yerleşim kaydı.
struct APISettlement: Codable {
    let id: Int
    let name: String
    let population: Int?
}

/// TurkiyeAPI liste yanıtı.
private struct APIListResponse<T: Codable>: Codable {
    let data: [T]
}

/// Ücretsiz TurkiyeAPI istemcisi — mahalle/köy doğrulama.
actor TurkiyeAPIClient {
    static let shared = TurkiyeAPIClient()

    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// İlçedeki mahalleleri arar.
    func searchNeighborhoods(districtId: Int, query: String, limit: Int = 10) async throws -> [APISettlement] {
        try await fetchSettlements(
            path: "/districts/\(districtId)/neighborhoods",
            query: query,
            limit: limit
        )
    }

    /// İlçedeki köyleri arar.
    func searchVillages(districtId: Int, query: String, limit: Int = 10) async throws -> [APISettlement] {
        try await fetchSettlements(
            path: "/districts/\(districtId)/villages",
            query: query,
            limit: limit
        )
    }

    private func fetchSettlements(path: String, query: String, limit: Int) async throws -> [APISettlement] {
        var components = URLComponents(string: Constants.turkiyeAPIBaseURL + path)
        var items = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "fields", value: "id,name,population")
        ]
        if !query.isEmpty {
            items.append(URLQueryItem(name: "search", value: query))
        }
        components?.queryItems = items

        guard let url = components?.url else { return [] }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw LokusError.networkUnavailable
        }

        let decoded = try decoder.decode(APIListResponse<APISettlement>.self, from: data)
        return decoded.data
    }
}
