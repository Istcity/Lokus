// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import CoreLocation
import Foundation

/// Konum → il/ilçe/mahalle çözümlemesi ve profil üretimi.
@MainActor
final class SettlementResolver: ObservableObject {
    private let locationAnalyzer = LocationAnalyzer()
    private let adminStore = AdministrativeDataStore.shared
    private let apiClient = TurkiyeAPIClient.shared
    private let cache = SettlementCache.shared

    /// Koordinat için tam yerleşim profili üretir.
    func resolve(at coordinate: CLLocationCoordinate2D) async throws -> ResolvedSettlement {
        let location = try await locationAnalyzer.resolveLocation(coordinate)
        LocationViewModel.shared.update(from: location)

        guard let (province, district) = try adminStore.district(
            provinceName: location.provinceName,
            districtName: location.districtName
        ) else {
            return try fallbackSettlement(location: location)
        }

        let cacheKey = "\(province.plateNumber)-\(district.apiId)-\(GeoUtils.normalize(location.villageName))"
        var apiMatch: APISettlement?
        var dataSource: SettlementDataSource = .estimated
        var isSettlementNeighborhood = inferSettlementType(from: location.villageName, district: district)

        if let cached = await cache.get(key: cacheKey) {
            apiMatch = cached
            dataSource = .apiVerified
        } else {
            if let neighborhood = await findOnlineSettlement(
                district: district,
                settlementName: location.villageName,
                preferNeighborhoods: true
            ) {
                apiMatch = neighborhood
                isSettlementNeighborhood = true
                dataSource = .apiVerified
            } else if let village = await findOnlineSettlement(
                district: district,
                settlementName: location.villageName,
                preferNeighborhoods: false
            ) {
                apiMatch = village
                isSettlementNeighborhood = false
                dataSource = .apiVerified
            } else {
                dataSource = .hybrid
            }

            if let apiMatch {
                await cache.set(key: cacheKey, settlement: apiMatch)
            }
        }

        let village = RegionEstimator.estimateVillage(
            settlementName: location.villageName,
            district: district,
            province: province,
            population: apiMatch?.population,
            dataSource: dataSource,
            apiSettlementName: apiMatch?.name,
            isSettlementNeighborhood: isSettlementNeighborhood
        )

        let villageWithOverride = ParcelZoningStore.shared.applyOverride(to: village, at: coordinate)

        return ResolvedSettlement(
            village: villageWithOverride,
            provinceName: province.name,
            districtName: district.name,
            settlementName: apiMatch?.name ?? location.villageName,
            districtId: district.apiId,
            provincePlate: province.plateNumber,
            dataSource: dataSource,
            officialPopulation: apiMatch?.population,
            isNeighborhood: isSettlementNeighborhood
        )
    }

    private func findOnlineSettlement(
        district: DistrictIndex,
        settlementName: String,
        preferNeighborhoods: Bool
    ) async -> APISettlement? {
        let query = cleanedSearchQuery(from: settlementName)
        guard !query.isEmpty else { return nil }

        do {
            if preferNeighborhoods, (district.neighborhoodCount ?? 0) > 0 {
                let neighborhoods = try await apiClient.searchNeighborhoods(districtId: district.apiId, query: query)
                if let match = bestMatch(in: neighborhoods, for: settlementName) {
                    return match
                }
            }

            if !preferNeighborhoods, (district.villageCount ?? 0) > 0 {
                let villages = try await apiClient.searchVillages(districtId: district.apiId, query: query)
                return bestMatch(in: villages, for: settlementName)
            }
        } catch {
            return nil
        }

        return nil
    }

    private func inferSettlementType(from name: String, district: DistrictIndex) -> Bool {
        let lowered = name.lowercased()
        if lowered.contains("köy") { return false }
        if lowered.contains("mah") { return true }
        return (district.neighborhoodCount ?? 0) >= (district.villageCount ?? 0)
    }

    private func bestMatch(in settlements: [APISettlement], for name: String) -> APISettlement? {
        if let exact = settlements.first(where: { GeoUtils.namesMatch($0.name, name) }) {
            return exact
        }
        return settlements.first
    }

    private func cleanedSearchQuery(from name: String) -> String {
        name
            .replacingOccurrences(of: " Mah.", with: "")
            .replacingOccurrences(of: " Mah", with: "")
            .replacingOccurrences(of: " Köyü", with: "")
            .replacingOccurrences(of: " Köy", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackSettlement(location: LocationResult) throws -> ResolvedSettlement {
        guard let province = try adminStore.province(matching: location.provinceName),
              let district = province.districts.first else {
            throw LokusError.regionDataNotFound
        }

        let isNeighborhood = inferSettlementType(from: location.villageName, district: district)
        let village = RegionEstimator.estimateVillage(
            settlementName: location.villageName,
            district: district,
            province: province,
            dataSource: .estimated,
            isSettlementNeighborhood: isNeighborhood
        )

        return ResolvedSettlement(
            village: village,
            provinceName: province.name,
            districtName: district.name,
            settlementName: location.villageName,
            districtId: district.apiId,
            provincePlate: province.plateNumber,
            dataSource: .estimated,
            officialPopulation: nil,
            isNeighborhood: isNeighborhood
        )
    }
}
