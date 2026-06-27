// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// TKGM MEGSİS kamu API parsel sonucu.
struct TKGMParcelResult: Codable, Equatable {
    let ilAd: String
    let ilceAd: String
    let mahalleAd: String
    let mahalleId: Int
    let adaNo: String
    let parselNo: String
    let alan: String?
    let nitelik: String?
    let ozet: String?

    var adaParselLabel: String { "\(adaNo) / \(parselNo)" }
}

/// TKGM koordinat → parsel kamu API istemcisi.
actor TKGMParcelService {
    static let shared = TKGMParcelService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        session = URLSession(configuration: config)
    }

    func lookup(at coordinate: CLLocationCoordinate2D) async -> TKGMParcelResult? {
        let lat = String(format: "%.6f", coordinate.latitude)
        let lng = String(format: "%.6f", coordinate.longitude)
        let candidates = [
            "https://cbsapi.tkgm.gov.tr/megsiswebapi.v3.1/api/parsel/\(lat)/\(lng)",
            "https://cbsapi.tkgm.gov.tr/megsiswebapi.v3/api/parsel/\(lat)/\(lng)"
        ]

        for urlString in candidates {
            guard let url = URL(string: urlString) else { continue }
            if let result = await fetch(from: url) {
                return result
            }
        }
        return nil
    }

    private func fetch(from url: URL) async -> TKGMParcelResult? {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return parse(data: data)
        } catch {
            return nil
        }
    }

    private func parse(data: Data) -> TKGMParcelResult? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let props = root["properties"] as? [String: Any],
              let mahalleId = props["mahalleId"] as? Int,
              let ada = props["adaNo"] as? String,
              let parsel = props["parselNo"] as? String,
              let ilAd = props["ilAd"] as? String,
              let ilceAd = props["ilceAd"] as? String,
              let mahalleAd = props["mahalleAd"] as? String else {
            return nil
        }

        return TKGMParcelResult(
            ilAd: ilAd,
            ilceAd: ilceAd,
            mahalleAd: mahalleAd,
            mahalleId: mahalleId,
            adaNo: ada,
            parselNo: parsel,
            alan: props["alan"] as? String,
            nitelik: props["nitelik"] as? String,
            ozet: props["ozet"] as? String
        )
    }
}
