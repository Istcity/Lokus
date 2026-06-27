// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import CoreLocation
import Foundation

/// Fizibilite analizi ViewModel'i.
@MainActor
final class ROIViewModel: ObservableObject {
    @Published var village: Village?
    @Published var landAreaM2: Double = 500
    @Published var salePricePerM2: Double = 0
    @Published var constructionCostPerM2: Double = 18_500
    @Published var monthlyRent: Double = 0
    @Published var annualGrowthRate: Double = 12
    @Published var costSource: CostSource = .marketAvg
    @Published var result: ROIResult?
    @Published private(set) var santiyeAsistCosts: ConstructionCosts?
    @Published private(set) var rentUsesAutoEstimate = true

    private let appGroupManager = AppGroupManager.shared
    private var manualConstructionCost: Double = 18_500

    var isSantiyeAsistAvailable: Bool { santiyeAsistCosts != nil }
    var constructionCostIsEditable: Bool { costSource == .manual }

    /// Önceden yüklenmiş köy ile başlatır.
    func configure(with preloadedVillage: Village?) async {
        refreshSantiyeAsistStatus()

        if let preloadedVillage {
            village = preloadedVillage
            salePricePerM2 = preloadedVillage.housePricePerM2
            estimateMonthlyRent(force: true)
        } else if let location = LocationViewModel.shared.selectedCoordinate {
            await loadVillageFromCoordinate(location)
        } else {
            await loadDefaultVillage()
        }

        if santiyeAsistCosts != nil {
            costSource = .santiyeAsist
        }

        applyCostSource(costSource)
        calculate()
    }

    /// Şantiye Asist verisini yeniden okur.
    func refreshSantiyeAsistStatus() {
        santiyeAsistCosts = appGroupManager.loadConstructionCosts()
    }

    /// Maliyet kaynağına göre inşaat maliyetini günceller.
    func applyCostSource(_ source: CostSource) {
        if costSource == .manual, source != .manual {
            manualConstructionCost = constructionCostPerM2
        }

        costSource = source
        switch source {
        case .santiyeAsist:
            refreshSantiyeAsistStatus()
            if let costs = santiyeAsistCosts {
                constructionCostPerM2 = costs.derivedBuildingCostPerM2
            } else {
                constructionCostPerM2 = 18_000
            }
        case .manual:
            constructionCostPerM2 = manualConstructionCost
        case .marketAvg:
            constructionCostPerM2 = 18_500
        }
        calculate()
    }

    /// Kira tahminini yeniden hesaplar.
    func estimateMonthlyRent(force: Bool = false) {
        guard force || rentUsesAutoEstimate else { return }
        guard let village else { return }
        let grossArea = ROIFormulas.buildableArea(landM2: landAreaM2, kaks: village.zoning.kaks)
        monthlyRent = grossArea * village.housePricePerM2 * 0.004
        rentUsesAutoEstimate = true
    }

    /// Kullanıcı kira girdisini manuel değiştirdiğinde çağrılır.
    func userDidEditRent() {
        rentUsesAutoEstimate = false
        calculate()
    }

    /// Girdi değişikliklerinde fizibilite hesaplar.
    func calculate() {
        guard let village else {
            result = nil
            return
        }

        if rentUsesAutoEstimate {
            estimateMonthlyRent(force: true)
        }

        let grossArea = ROIFormulas.buildableArea(landM2: landAreaM2, kaks: village.zoning.kaks)
        let input = ROIInput(
            landAreaM2: landAreaM2,
            landPricePerM2: village.landPricePerM2,
            constructionCostPerM2: constructionCostPerM2,
            grossFloorArea: grossArea,
            salePricePerM2: salePricePerM2
        )

        result = ROIFormulas.calculate(
            input: input,
            annualGrowthRate: annualGrowthRate,
            monthlyRent: monthlyRent
        )
    }

    /// İl/ilçe seçimine göre bölge profili yükler.
    func loadVillage(province: ProvinceIndex, district: DistrictIndex) {
        let estimated = RegionEstimator.estimateVillage(
            settlementName: district.name,
            district: district,
            province: province,
            dataSource: .localIndex
        )
        village = estimated
        salePricePerM2 = estimated.housePricePerM2
        estimateMonthlyRent(force: true)
        calculate()
    }

    /// Keşfet'ten paylaşılan konumdan bölge yükler.
    func loadVillageFromCoordinate(_ coordinate: CLLocationCoordinate2D) async {
        let resolver = SettlementResolver()
        do {
            let resolved = try await resolver.resolve(at: coordinate)
            village = resolved.village
            if salePricePerM2 == 0 {
                salePricePerM2 = resolved.village.housePricePerM2
            }
            estimateMonthlyRent(force: true)
            calculate()
        } catch {
            await loadDefaultVillage()
        }
    }

    private func loadDefaultVillage() async {
        guard let index = try? AdministrativeDataStore.shared.loadIndex() else { return }

        let plate = LocationViewModel.shared.provinceName.isEmpty
            ? 6
            : (index.provinces.first { $0.name == LocationViewModel.shared.provinceName }?.plateNumber ?? 6)

        let province = index.provinces.first(where: { $0.plateNumber == plate }) ?? index.provinces.first
        guard let province else { return }

        let districtName = LocationViewModel.shared.districtName
        let district = province.districts.first { $0.name == districtName } ?? province.districts.first
        guard let district else { return }

        loadVillage(province: province, district: district)
    }
}
