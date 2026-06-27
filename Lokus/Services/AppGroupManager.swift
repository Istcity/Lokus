// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// Şantiye Asist ve widget ile paylaşılan App Group verileri.
final class AppGroupManager {
    static let shared = AppGroupManager()

    private let groupID = Constants.appGroupID

    struct Keys {
        static let concreteCostM3 = "santiyek_beton_m3"
        static let steelCostTon = "santiyek_demir_ton"
        static let laborCostHour = "santiyek_iscilik_saat"
        static let scaffoldCostM2 = "santiyek_iskele_m2"
        static let lastUpdated = "santiyek_lastUpdated"

        static let handoffLatitude = "lokus_handoff_lat"
        static let handoffLongitude = "lokus_handoff_lon"
        static let handoffAddress = "lokus_handoff_address"
        static let handoffVillageName = "lokus_handoff_village"
        static let handoffTimestamp = "lokus_handoff_timestamp"

        static let lastRegionName = "lokus_last_region_name"
        static let lastRegionDistrict = "lokus_last_region_district"
        static let lastRegionProvince = "lokus_last_region_province"
        static let lastHousePrice = "lokus_last_house_price"
        static let lastLatitude = "lokus_last_lat"
        static let lastLongitude = "lokus_last_lon"
    }

    private init() {}

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: groupID)
    }

    func loadConstructionCosts() -> ConstructionCosts? {
        guard let defaults else { return nil }

        let concrete = defaults.double(forKey: Keys.concreteCostM3)
        let steel = defaults.double(forKey: Keys.steelCostTon)
        let labor = defaults.double(forKey: Keys.laborCostHour)
        let scaffold = defaults.double(forKey: Keys.scaffoldCostM2)

        guard concrete > 0, steel > 0, labor > 0 else { return nil }

        let lastUpdated = defaults.object(forKey: Keys.lastUpdated) as? Date ?? Date()
        let derivedCost = deriveBuildingCostPerM2(
            concretePerM3: concrete,
            steelPerTon: steel,
            laborPerHour: labor,
            scaffoldPerM2: scaffold
        )

        return ConstructionCosts(
            concreteCostPerM3: concrete,
            steelCostPerTon: steel,
            laborCostPerHour: labor,
            scaffoldCostPerM2: scaffold > 0 ? scaffold : 120,
            derivedBuildingCostPerM2: derivedCost,
            lastUpdated: lastUpdated
        )
    }

    /// Keşfet → Şantiye Asist / Fizibilite konum aktarımı.
    func saveLocationHandoff(
        coordinate: CLLocationCoordinate2D,
        address: String,
        villageName: String
    ) {
        guard let defaults else { return }
        defaults.set(coordinate.latitude, forKey: Keys.handoffLatitude)
        defaults.set(coordinate.longitude, forKey: Keys.handoffLongitude)
        defaults.set(address, forKey: Keys.handoffAddress)
        defaults.set(villageName, forKey: Keys.handoffVillageName)
        defaults.set(Date(), forKey: Keys.handoffTimestamp)
    }

    /// Şantiye Asist veya widget'tan gelen konumu okur.
    func loadLocationHandoff() -> SharedLocationHandoff? {
        guard let defaults else { return nil }
        let lat = defaults.double(forKey: Keys.handoffLatitude)
        let lon = defaults.double(forKey: Keys.handoffLongitude)
        guard lat != 0, lon != 0 else { return nil }

        return SharedLocationHandoff(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            address: defaults.string(forKey: Keys.handoffAddress) ?? "",
            villageName: defaults.string(forKey: Keys.handoffVillageName) ?? "",
            timestamp: defaults.object(forKey: Keys.handoffTimestamp) as? Date ?? Date()
        )
    }

    func clearLocationHandoff() {
        guard let defaults else { return }
        defaults.removeObject(forKey: Keys.handoffLatitude)
        defaults.removeObject(forKey: Keys.handoffLongitude)
        defaults.removeObject(forKey: Keys.handoffAddress)
        defaults.removeObject(forKey: Keys.handoffVillageName)
        defaults.removeObject(forKey: Keys.handoffTimestamp)
    }

    /// Widget için son görüntülenen bölge.
    func saveLastViewedRegion(_ location: SavedLocation) {
        guard let defaults else { return }
        defaults.set(location.name, forKey: Keys.lastRegionName)
        defaults.set(location.districtName, forKey: Keys.lastRegionDistrict)
        defaults.set(location.provinceName, forKey: Keys.lastRegionProvince)
        defaults.set(location.village.housePricePerM2, forKey: Keys.lastHousePrice)
        defaults.set(location.latitude, forKey: Keys.lastLatitude)
        defaults.set(location.longitude, forKey: Keys.lastLongitude)
    }

    func saveLastViewedRegion(
        name: String,
        district: String,
        province: String,
        housePrice: Double,
        coordinate: CLLocationCoordinate2D
    ) {
        guard let defaults else { return }
        defaults.set(name, forKey: Keys.lastRegionName)
        defaults.set(district, forKey: Keys.lastRegionDistrict)
        defaults.set(province, forKey: Keys.lastRegionProvince)
        defaults.set(housePrice, forKey: Keys.lastHousePrice)
        defaults.set(coordinate.latitude, forKey: Keys.lastLatitude)
        defaults.set(coordinate.longitude, forKey: Keys.lastLongitude)
    }

    private func deriveBuildingCostPerM2(
        concretePerM3: Double,
        steelPerTon: Double,
        laborPerHour: Double,
        scaffoldPerM2: Double
    ) -> Double {
        let concreteComponent = concretePerM3 * 0.35
        let steelComponent = (steelPerTon / 1000.0) * 85.0
        let laborComponent = laborPerHour * 18.0
        return concreteComponent + steelComponent + laborComponent + scaffoldPerM2
    }
}

struct ConstructionCosts {
    let concreteCostPerM3: Double
    let steelCostPerTon: Double
    let laborCostPerHour: Double
    let scaffoldCostPerM2: Double
    let derivedBuildingCostPerM2: Double
    let lastUpdated: Date
}

struct SharedLocationHandoff {
    let coordinate: CLLocationCoordinate2D
    let address: String
    let villageName: String
    let timestamp: Date
}
