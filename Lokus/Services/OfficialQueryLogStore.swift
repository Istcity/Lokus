// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

enum OfficialQueryKind: String, Codable, CaseIterable {
    case parcel
    case zoning
    case infrastructure

    var title: String {
        switch self {
        case .parcel: "Parsel (TKGM)"
        case .zoning: "İmar / e-Plan"
        case .infrastructure: "Altyapı"
        }
    }

    var icon: String {
        switch self {
        case .parcel: "map"
        case .zoning: "building.2"
        case .infrastructure: "bolt"
        }
    }
}

enum OfficialQueryStatus: String, Codable {
    case pending
    case openedWeb
    case resolvedViaAPI
}

/// Seçilen nokta için resmi kaynak sorgu kaydı.
struct OfficialQueryRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let latitude: Double
    let longitude: Double
    let provinceName: String
    let districtName: String
    let settlementName: String?
    let kind: OfficialQueryKind
    var status: OfficialQueryStatus
    var mahalleId: Int?
    var adaNo: String?
    var parselNo: String?
    var openedURL: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var locationLabel: String {
        if let settlementName {
            return "\(settlementName), \(districtName)"
        }
        return "\(districtName), \(provinceName)"
    }

    var detailLabel: String? {
        if let adaNo, let parselNo {
            return "Ada \(adaNo) / Parsel \(parselNo)"
        }
        return String(format: "%.5f, %.5f", latitude, longitude)
    }
}

/// Veri alınamayan noktalar için resmi sorgu günlüğü.
final class OfficialQueryLogStore: ObservableObject {
    static let shared = OfficialQueryLogStore()

    @Published private(set) var records: [OfficialQueryRecord] = []

    private let storageKey = "official_query_log_v1"
    private let maxRecords = 80

    private init() {
        load()
    }

    @discardableResult
    func recordPending(
        kind: OfficialQueryKind,
        coordinate: CLLocationCoordinate2D,
        settlement: ResolvedSettlement?,
        tkgm: TKGMParcelResult? = nil
    ) -> UUID {
        if isDuplicate(kind: kind, coordinate: coordinate) {
            return records.first(where: {
                $0.kind == kind
                    && abs($0.latitude - coordinate.latitude) < 0.0001
                    && abs($0.longitude - coordinate.longitude) < 0.0001
            })?.id ?? UUID()
        }

        let entry = OfficialQueryRecord(
            id: UUID(),
            createdAt: Date(),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            provinceName: settlement?.provinceName ?? "—",
            districtName: settlement?.districtName ?? "—",
            settlementName: settlement?.settlementName,
            kind: kind,
            status: tkgm == nil ? .pending : .resolvedViaAPI,
            mahalleId: tkgm?.mahalleId,
            adaNo: tkgm?.adaNo,
            parselNo: tkgm?.parselNo,
            openedURL: nil
        )
        records.insert(entry, at: 0)
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        save()
        return entry.id
    }

    func markOpened(id: UUID, url: URL) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].status = .openedWeb
        records[index].openedURL = url.absoluteString
        save()
    }

    func remove(id: UUID) {
        records.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        records = []
        save()
    }

    func recent(for kind: OfficialQueryKind, limit: Int = 5) -> [OfficialQueryRecord] {
        Array(records.filter { $0.kind == kind }.prefix(limit))
    }

    private func isDuplicate(kind: OfficialQueryKind, coordinate: CLLocationCoordinate2D) -> Bool {
        records.contains {
            $0.kind == kind
                && abs($0.latitude - coordinate.latitude) < 0.0001
                && abs($0.longitude - coordinate.longitude) < 0.0001
                && Date().timeIntervalSince($0.createdAt) < 300
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([OfficialQueryRecord].self, from: data) else {
            return
        }
        records = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
