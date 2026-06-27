// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Harita katmanları — kompakt yüzen düğme + alt sayfa.
struct MapLayerToolbar: View {
    @Binding var activeOverlays: Set<MapOverlayType>
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "square.3.layers.3d")
                    .font(.title3)
                    .foregroundStyle(Color("AccentOrange"))
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(radius: 2)

                if activeOverlays.count > 0 {
                    Text("\(activeOverlays.count)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color("AccentOrange"), in: Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
        .accessibilityLabel("Harita katmanları")
        .sheet(isPresented: $showSheet) {
            MapLayerSheet(activeOverlays: $activeOverlays)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

struct MapLayerSheet: View {
    @Binding var activeOverlays: Set<MapOverlayType>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Katmanlar yalnızca geo backend veya pilot seed alanında (ör. Kadıköy) görünür. Veri yoksa alt panelden resmi kaynaklara gidebilirsiniz.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Harita Katmanları") {
                    ForEach(MapOverlayType.allCases) { layer in
                        Button {
                            toggle(layer)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: layer.icon)
                                    .frame(width: 28)
                                    .foregroundStyle(activeOverlays.contains(layer) ? Color("AccentOrange") : .secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(layer.title)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(layer.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: activeOverlays.contains(layer) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(activeOverlays.contains(layer) ? Color("AccentOrange") : Color.secondary.opacity(0.4))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Katmanlar")
            .navigationBarTitleDisplayMode(.inline)
            .lokusNavigationBarLogo()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") { dismiss() }
                }
            }
        }
    }

    private func toggle(_ layer: MapOverlayType) {
        if activeOverlays.contains(layer) {
            activeOverlays.remove(layer)
        } else {
            activeOverlays.insert(layer)
        }
    }
}
