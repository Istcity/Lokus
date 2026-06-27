// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Backend altyapı grid bileşeni.
struct InfrastructureGrid: View {
    let infra: GeoInfrastructureData

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            InfraGridItem(icon: "road.lanes", label: "Yol", available: infra.yol)
            InfraGridItem(icon: "drop.fill", label: "Su", available: infra.su)
            InfraGridItem(icon: "bolt.fill", label: "Elektrik", available: infra.elektrik)
            InfraGridItem(icon: "flame.fill", label: "Doğalgaz", available: infra.dogalgaz)
            InfraGridItem(icon: "wifi", label: "Fiber", available: infra.fiber)
            InfraGridItem(icon: "bus.fill", label: "Toplu T.", available: infra.topluTasima)
        }
    }
}

struct InfraGridItem: View {
    let icon: String
    let label: String
    let available: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(available ? Color("SuccessGreen") : .secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Circle()
                .fill(available ? Color("SuccessGreen") : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
    }
}
