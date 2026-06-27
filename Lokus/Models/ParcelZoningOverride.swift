// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import Foundation

/// Kullanıcının çap / e-Plan bilgisiyle girdiği parsel imarı.
struct ParcelZoningOverride: Codable, Identifiable, Hashable {
    var id: String { locationKey }
    let locationKey: String
    var taks: Double
    var kaks: Double
    var maxFloors: String
    var status: ZoningStatus
    var capReference: String
    var notes: String
    var updatedAt: Date

    var zoningInfo: ZoningInfo {
        ZoningInfo(taks: taks, kaks: kaks, maxFloors: maxFloors, status: status)
    }

    static func locationKey(latitude: Double, longitude: Double) -> String {
        String(format: "%.4f,%.4f", latitude, longitude)
    }
}
