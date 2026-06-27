// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import UIKit

/// Bölge ve fizibilite PDF raporu üretir.
final class RegionReportGenerator {
    private let pdf = PDFGenerator()

    func generateRegionReport(
        village: Village,
        settlement: ResolvedSettlement?,
        coordinate: CLLocationCoordinate2D?,
        roiResult: ROIResult?,
        roiInputs: (landM2: Double, salePrice: Double, constructionCost: Double)?
    ) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let body = buildReportText(
            village: village,
            settlement: settlement,
            coordinate: coordinate,
            roiResult: roiResult,
            roiInputs: roiInputs
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.label
        ]

        let data = renderer.pdfData { context in
            context.beginPage()
            var contentTop: CGFloat = 36
            if let logo = UIImage(named: "LokusLogo") {
                let logoHeight: CGFloat = 56
                let aspect = logo.size.width / max(logo.size.height, 1)
                let logoWidth = logoHeight * aspect
                logo.draw(in: CGRect(x: 40, y: 28, width: logoWidth, height: logoHeight))
                contentTop = 28 + logoHeight + 12
            }
            "Bölge Analiz Raporu".draw(
                in: CGRect(x: 40, y: contentTop, width: pageRect.width - 80, height: 24),
                withAttributes: titleAttributes
            )
            "Oluşturulma: \(Date().formatted(date: .long, time: .shortened))".draw(
                in: CGRect(x: 40, y: contentTop + 28, width: pageRect.width - 80, height: 18),
                withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.secondaryLabel]
            )
            body.draw(
                in: CGRect(x: 40, y: contentTop + 52, width: pageRect.width - 80, height: pageRect.height - contentTop - 72),
                withAttributes: bodyAttributes
            )
        }

        let fileName = "Lokus-\(village.name.replacingOccurrences(of: " ", with: "-"))-\(Int(Date().timeIntervalSince1970)).pdf"
        return try pdf.writeToTemporaryFile(data: data, fileName: fileName)
    }

    private func buildReportText(
        village: Village,
        settlement: ResolvedSettlement?,
        coordinate: CLLocationCoordinate2D?,
        roiResult: ROIResult?,
        roiInputs: (landM2: Double, salePrice: Double, constructionCost: Double)?
    ) -> String {
        var lines: [String] = []

        lines.append("YERLEŞİM")
        lines.append("────────")
        lines.append("Ad: \(village.name)")
        if let settlement {
            lines.append("İlçe / İl: \(settlement.districtName), \(settlement.provinceName)")
            lines.append("Veri kaynağı: \(settlement.dataSource.rawValue)")
            if let pop = settlement.officialPopulation {
                lines.append("Nüfus: \(pop.formatted())")
            }
        }
        if let coordinate {
            lines.append(String(format: "Koordinat: %.5f, %.5f", coordinate.latitude, coordinate.longitude))
        }

        lines.append("")
        lines.append("FİYAT TAHMİNİ")
        lines.append("────────")
        lines.append("Konut m²: \(village.housePricePerM2.formatted()) ₺")
        lines.append("Arsa m²: \(village.landPricePerM2.formatted()) ₺")

        lines.append("")
        lines.append("İMAR (TAHMİNİ)")
        lines.append("────────")
        lines.append("Durum: \(village.zoning.status.rawValue)")
        lines.append("TAKS (\(ZoningInfo.taksFullName)): \(village.zoning.taks)")
        lines.append("KAKS (\(ZoningInfo.kaksFullName)): \(village.zoning.kaks)")
        lines.append("Kat sınırı: \(village.zoning.maxFloors)")

        lines.append("")
        lines.append("ALTYAPI")
        lines.append("────────")
        let infra = village.infrastructure
        lines.append("Elektrik: \(infra.electricity ? "Var" : "Yok") · Su: \(infra.water ? "Var" : "Yok")")
        lines.append("Doğalgaz: \(infra.naturalGas ? "Var" : "Yok") · İnternet: \(infra.internet ? "Var" : "Yok")")

        if let roiResult, let inputs = roiInputs {
            lines.append("")
            lines.append("FİZİBİLİTE ÖZETİ")
            lines.append("────────")
            lines.append("Arsa: \(inputs.landM2.formatted()) m²")
            lines.append("Satış: \(inputs.salePrice.formatted()) ₺/m²")
            lines.append("İnşaat: \(inputs.constructionCost.formatted()) ₺/m²")
            lines.append("Toplam maliyet: \(roiResult.totalCost.formatted()) ₺")
            lines.append("Tahmini gelir: \(roiResult.totalRevenue.formatted()) ₺")
            lines.append("Brüt kâr: \(roiResult.grossProfit.formatted()) ₺")
            lines.append(String(format: "Kâr marjı: %.1f%%", roiResult.profitMargin))
            lines.append(String(format: "Kira getirisi: %.1f%%", roiResult.rentalYieldPercent))
        }

        if !village.notes.isEmpty {
            lines.append("")
            lines.append("NOTLAR")
            lines.append("────────")
            lines.append(village.notes)
        }

        lines.append("")
        lines.append("UYARI: Bu rapor bilgilendirme amaçlıdır. Resmi tapu, çap veya imar belgesi yerine geçmez.")

        return lines.joined(separator: "\n")
    }
}
