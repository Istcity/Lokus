// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI
import UIKit

/// Sistem paylaşım sayfası.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
