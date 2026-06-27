// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// En fazla 3 favori bölgeyi yan yana karşılaştırır.
struct CompareRegionsView: View {
    @Environment(\.dismiss) private var dismiss
    let locations: [SavedLocation]

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(locations) { location in
                        compareCard(for: location)
                            .frame(width: 260)
                    }
                }
                .padding()
            }
            .navigationTitle("Karşılaştırma")
            .navigationBarTitleDisplayMode(.inline)
            .lokusNavigationBarLogo()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func compareCard(for location: SavedLocation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(location.name)
                .font(.headline)
            Text("\(location.districtName), \(location.provinceName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            metric("Konut m²", value: "\(location.village.housePricePerM2.formatted()) ₺")
            metric("Arsa m²", value: "\(location.village.landPricePerM2.formatted()) ₺")
            metric("İmar", value: location.village.zoning.status.rawValue)
            metric("TAKS", value: String(format: "%.2f", location.village.zoning.taks))
            metric("KAKS", value: String(format: "%.2f", location.village.zoning.kaks))
            metric("Kat", value: location.village.zoning.maxFloors)

            HStack(spacing: 8) {
                infraDot("bolt.fill", location.village.infrastructure.electricity)
                infraDot("drop.fill", location.village.infrastructure.water)
                infraDot("flame.fill", location.village.infrastructure.naturalGas)
                infraDot("wifi", location.village.infrastructure.internet)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func metric(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
        }
    }

    private func infraDot(_ icon: String, _ active: Bool) -> some View {
        Image(systemName: icon)
            .font(.caption)
            .foregroundStyle(active ? Color("SuccessGreen") : Color("TextSecondary").opacity(0.3))
    }
}
