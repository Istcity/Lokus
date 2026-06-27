// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Kayıtlı bölgeler listesi.
struct FavoritesView: View {
    @ObservedObject private var store = FavoritesStore.shared
    @State private var selectedForCompare: Set<UUID> = []
    @State private var showCompare = false

    var body: some View {
        List {
            if store.favorites.isEmpty {
                ContentUnavailableView(
                    "Henüz favori yok",
                    systemImage: "star",
                    description: Text("Keşfet'te bir bölge seçip yıldız ikonuna dokunun.")
                )
            } else {
                Section {
                    if selectedForCompare.count >= 2 {
                        Button {
                            showCompare = true
                        } label: {
                            Label("Seçilenleri Karşılaştır (\(selectedForCompare.count))", systemImage: "arrow.left.arrow.right")
                        }
                    }
                }

                Section("Kayıtlı Bölgeler") {
                    ForEach(store.favorites) { favorite in
                        HStack {
                            Button {
                                toggleCompare(favorite.id)
                            } label: {
                                Image(systemName: selectedForCompare.contains(favorite.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Color("AccentOrange"))
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(favorite.name)
                                    .font(.headline)
                                Text("\(favorite.districtName), \(favorite.provinceName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Konut: \(favorite.village.housePricePerM2.formatted()) ₺/m²")
                                    .font(.caption2)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.remove(favorite)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                            Button {
                                AppRouter.shared.openExplore(at: favorite.coordinate)
                            } label: {
                                Label("Haritada Aç", systemImage: "map")
                            }
                            .tint(Color("AccentOrange"))
                        }
                    }
                }
            }
        }
        .navigationTitle("Favoriler")
        .navigationBarTitleDisplayMode(.inline)
        .lokusNavigationBarLogo()
        .sheet(isPresented: $showCompare) {
            CompareRegionsView(
                locations: store.favorites.filter { selectedForCompare.contains($0.id) }
            )
        }
        .onAppear { store.load() }
        .lokusAdBanner()
    }

    private func toggleCompare(_ id: UUID) {
        if selectedForCompare.contains(id) {
            selectedForCompare.remove(id)
        } else if selectedForCompare.count < 3 {
            selectedForCompare.insert(id)
        }
    }
}
