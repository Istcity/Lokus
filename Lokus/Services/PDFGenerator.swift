// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import PDFKit
import UIKit

/// PDFKit ile belge üretimi.
final class PDFGenerator {
    /// Şablon ve kullanıcı bilgilerinden A4 PDF verisi üretir.
    func generate(template: DocumentTemplate, userInfo: DocumentUserInfo) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]

        return renderer.pdfData { context in
            context.beginPage()
            let text = template.renderedText(userInfo: userInfo)
            let title = template.type.rawValue
            let titleRect = CGRect(x: 40, y: 40, width: pageRect.width - 80, height: 40)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            let bodyRect = CGRect(x: 40, y: 90, width: pageRect.width - 80, height: pageRect.height - 130)
            text.draw(in: bodyRect, withAttributes: attributes)
        }
    }

    /// PDF verisini geçici dosyaya yazar ve URL döner.
    func writeToTemporaryFile(data: Data, fileName: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }
}
