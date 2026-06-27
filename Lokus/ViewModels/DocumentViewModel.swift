// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import Foundation

/// Belge oluşturucu ViewModel'i.
@MainActor
final class DocumentViewModel: ObservableObject {
    @Published var selectedType: DocumentType = .imarDurumu
    @Published var fullName: String = ""
    @Published var address: String = ""
    @Published var parcelInfo: String = ""
    @Published var generatedPDFURL: URL?
    @Published var errorMessage: String?

    private let pdfGenerator = PDFGenerator()
    private let revenueCatService = RevenueCatService.shared

    /// Form geçerli mi kontrol eder.
    var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
            && !address.trimmingCharacters(in: .whitespaces).isEmpty
            && !parcelInfo.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Seçili şablondan PDF üretir.
    func generatePDF() {
        guard revenueCatService.hasPremiumAccess else {
            errorMessage = LokusError.premiumRequired.errorDescription
            return
        }

        guard isFormValid else {
            errorMessage = "Lütfen tüm alanları doldurun."
            return
        }

        let userInfo = DocumentUserInfo(
            fullName: fullName,
            address: address,
            parcelInfo: parcelInfo,
            date: Date()
        )
        let template = DocumentTemplate(type: selectedType)
        let data = pdfGenerator.generate(template: template, userInfo: userInfo)

        do {
            let fileName = "\(selectedType.rawValue.replacingOccurrences(of: " ", with: "_")).pdf"
            generatedPDFURL = try pdfGenerator.writeToTemporaryFile(data: data, fileName: fileName)
            errorMessage = nil
        } catch {
            errorMessage = "PDF oluşturulamadı: \(error.localizedDescription)"
        }
    }

    /// Konum ViewModel'inden adres bilgisini önceden doldurur.
    func prefillFromLocation() {
        let location = LocationViewModel.shared
        if address.isEmpty, !location.formattedAddress.isEmpty {
            address = location.formattedAddress
        }
    }
}
