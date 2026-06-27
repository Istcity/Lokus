// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import CoreLocation
import Foundation

/// Tapu türleri.
enum DeedType: String, CaseIterable, Identifiable {
    case mustakil = "Müstakil"
    case hisseli = "Hisseli"
    case katMulkiyeti = "Kat Mülkiyeti"
    case katIrtifaki = "Kat İrtifakı"

    var id: String { rawValue }

    var explanation: String {
        switch self {
        case .mustakil:
            return "Tek bir kişiye ait, bağımsız tapu kaydı. Satış ve ipotek işlemleri doğrudan yapılır."
        case .hisseli:
            return "Birden fazla malike ait paylı mülkiyet. Satış için diğer hissedarların rızası gerekebilir."
        case .katMulkiyeti:
            return "Yapı tamamlandıktan sonra bağımsız bölümlere verilen mülkiyet hakkı."
        case .katIrtifaki:
            return "Yapı devam ederken bağımsız bölümlere verilen irtifak hakkı; tamamlanınca kat mülkiyetine dönüşür."
        }
    }
}

/// Şerh türleri.
enum AnnotationType: String, CaseIterable, Identifiable {
    case none = "Şerh Yok"
    case ipotek = "İpotek"
    case haciz = "Haciz"
    case irtifak = "İrtifak Hakkı"
    case kamu = "Kamu Hakkı"

    var id: String { rawValue }

    var explanation: String {
        switch self {
        case .none: return "Tapu kaydında şerh bulunmuyor."
        case .ipotek: return "Banka kredisi karşılığı konulan ipotek. Satış öncesi kaldırılmalıdır."
        case .haciz: return "Borç nedeniyle konulan haciz şerhi. Satış engellenebilir."
        case .irtifak: return "Geçit, kullanım vb. irtifak hakları tapuya işlenmiş."
        case .kamu: return "Kamulaştırma, acele kamulaştırma veya kamu yararı şerhi."
        }
    }
}

/// Tapu asistanı adımları.
enum TapuStep: Int, CaseIterable {
    case deedType = 0
    case annotation
    case zoning
    case earthquake
    case summary
}

/// Tapu & Hukuk asistanı ViewModel'i.
@MainActor
final class TapuViewModel: ObservableObject {
    @Published var currentStep: TapuStep = .deedType
    @Published var selectedDeedType: DeedType?
    @Published var hasAnnotation = false
    @Published var selectedAnnotation: AnnotationType = .none
    @Published var nearestFaultName: String = ""
    @Published var faultDistanceKm: Double = 0
    @Published var riskLevel: RiskLevel = .low
    @Published var faultLines: [FaultLine] = []

    private let dataLoader = DataLoader()
    private let locationViewModel = LocationViewModel.shared

    /// Fay verilerini yükler ve konum riskini hesaplar.
    func loadData() {
        faultLines = (try? dataLoader.loadFaultLines()) ?? []
        assessEarthquakeRisk()
    }

    /// Sonraki adıma geçer.
    func nextStep() {
        guard let next = TapuStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
        if currentStep == .earthquake {
            assessEarthquakeRisk()
        }
    }

    /// Önceki adıma döner.
    func previousStep() {
        guard let previous = TapuStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previous
    }

    /// İmar durumu sorgulama rehber metni.
    var zoningGuideText: String {
        """
        İmar durumu (çap) belgesi almak için:

        1. Taşınmazın bağlı olduğu belediyenin İmar ve Şehircilik Müdürlüğü'ne başvurun.
        2. Tapu senedi, kimlik fotokopisi ve dilekçe ile müracaat edin.
        3. E-Devlet üzerinden de bazı belediyelerde online başvuru mümkündür.
        4. Çap belgesi TAKS, KAKS, yapı yüksekliği ve imar fonksiyonunu gösterir.
        5. Resmi belge olmadan yatırım kararı vermeyin.

        Bölgeniz: \(locationViewModel.districtName.isEmpty ? "Belirtilmedi" : locationViewModel.districtName), \
        \(locationViewModel.provinceName.isEmpty ? "" : locationViewModel.provinceName)
        """
    }

    /// Genel risk skorunu hesaplar.
    var overallRiskScore: RiskLevel {
        var score = 0
        if riskLevel == .high { score += 3 }
        else if riskLevel == .medium { score += 2 }
        else { score += 1 }

        if hasAnnotation { score += 2 }
        if selectedDeedType == .hisseli { score += 1 }

        if score >= 5 { return .high }
        if score >= 3 { return .medium }
        return .low
    }

    private func assessEarthquakeRisk() {
        guard let coordinate = locationViewModel.selectedCoordinate else {
            nearestFaultName = "Konum bilgisi yok"
            faultDistanceKm = 0
            riskLevel = .medium
            return
        }

        var nearest: (fault: FaultLine, distance: Double)?

        for fault in faultLines {
            let distance = GeoUtils.distanceToSegment(
                point: coordinate,
                segmentStart: fault.startCoordinate,
                segmentEnd: fault.endCoordinate
            )
            if nearest == nil || distance < nearest!.distance {
                nearest = (fault, distance)
            }
        }

        if let nearest {
            nearestFaultName = nearest.fault.name
            faultDistanceKm = nearest.distance
            riskLevel = RiskLevel.from(distanceKm: nearest.distance)
        }
    }
}
