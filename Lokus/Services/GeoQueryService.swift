// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

enum GeoQueryError: LocalizedError {
    case backendNotConfigured
    case serverError(Int)
    case decodingFailed
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .backendNotConfigured:
            return "Geo backend yapılandırılmamış."
        case .serverError(let code):
            return "Sunucu hatası (\(code))."
        case .decodingFailed:
            return "Yanıt çözümlenemedi."
        case .networkUnavailable:
            return "Geo API'ye ulaşılamadı."
        }
    }
}

/// Lokus Geo Backend istemcisi — tüm kurum sorguları bu servis üzerinden.
actor GeoQueryService {
    static let shared = GeoQueryService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let cache = GeoQueryCache.shared

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Koordinat için backend analizi; başarısız olursa nil döner.
    func queryLocation(
        lat: Double,
        lng: Double,
        radiusM: Int = 500
    ) async throws -> LocationAnalysisResult {
        guard AppConfiguration.isGeoBackendConfigured,
              let base = AppConfiguration.geoBackendURL else {
            throw GeoQueryError.backendNotConfigured
        }

        var components = URLComponents(url: base.appendingPathComponent("api/query"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lng", value: String(lng)),
            URLQueryItem(name: "radius_m", value: String(radiusM))
        ]

        guard let url = components.url else { throw GeoQueryError.networkUnavailable }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw GeoQueryError.networkUnavailable
        }
        guard http.statusCode == 200 else {
            throw GeoQueryError.serverError(http.statusCode)
        }

        do {
            let result = try decoder.decode(LocationAnalysisResult.self, from: data)
            await cache.save(result, for: CLLocationCoordinate2D(latitude: lat, longitude: lng))
            return result
        } catch {
            throw GeoQueryError.decodingFailed
        }
    }

    /// Backend erişilemezse önbellekten okur.
    func cachedResult(for coordinate: CLLocationCoordinate2D) async -> LocationAnalysisResult? {
        await cache.load(for: coordinate)
    }

    func vectorTileBaseURL() -> URL? {
        guard AppConfiguration.isGeoBackendConfigured,
              let base = AppConfiguration.geoBackendURL else { return nil }
        return base.appendingPathComponent("tiles")
    }
}
