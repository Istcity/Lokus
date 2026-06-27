// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Profil — resmi kaynak sorgu geçmişi.
struct OfficialQueryHistoryView: View {
    @ObservedObject private var store = OfficialQueryLogStore.shared
    @State private var safariURL: URL?
    @State private var showSafari = false
    @State private var showClearConfirm = false

    var body: some View {
        Group {
            if store.records.isEmpty {
                ContentUnavailableView(
                    "Henüz sorgu kaydı yok",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Haritada bir nokta seçtiğinizde ve resmi kaynak verisi alınamadığında kayıtlar burada görünür.")
                )
            } else {
                List {
                    ForEach(store.records) { record in
                        OfficialQueryHistoryRow(record: record) {
                            openWeb(record)
                        } onMap: {
                            AppRouter.shared.openExplore(at: record.coordinate)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("Sorgu Geçmişi")
        .navigationBarTitleDisplayMode(.inline)
        .lokusNavigationBarLogo()
        .toolbar {
            if !store.records.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Temizle", role: .destructive) {
                        showClearConfirm = true
                    }
                }
            }
        }
        .confirmationDialog("Tüm sorgu kayıtları silinsin mi?", isPresented: $showClearConfirm) {
            Button("Tümünü Sil", role: .destructive) {
                store.clearAll()
            }
            Button("İptal", role: .cancel) {}
        }
        .sheet(isPresented: $showSafari) {
            if let safariURL {
                SafariSheet(url: safariURL)
                    .ignoresSafeArea()
            }
        }
        .lokusAdBanner()
    }

    private func openWeb(_ record: OfficialQueryRecord) {
        let url = OfficialQueryLinks.url(for: record)
        store.markOpened(id: record.id, url: url)
        safariURL = url
        showSafari = true
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            store.remove(id: store.records[index].id)
        }
    }
}

private struct OfficialQueryHistoryRow: View {
    let record: OfficialQueryRecord
    let onWeb: () -> Void
    let onMap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(record.kind.title, systemImage: record.kind.icon)
                    .font(.subheadline.bold())
                Spacer()
                statusBadge
            }

            Text(record.locationLabel)
                .font(.footnote)

            if let detail = record.detailLabel {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 8) {
                Button(action: onWeb) {
                    Label("Web'de Aç", systemImage: "safari")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onMap) {
                    Label("Haritada", systemImage: "map")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch record.status {
        case .pending:
            Text("Bekliyor")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color("WarningAmber").opacity(0.2), in: Capsule())
                .foregroundStyle(Color("WarningAmber"))
        case .openedWeb:
            Text("Açıldı")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color("AccentOrange").opacity(0.15), in: Capsule())
                .foregroundStyle(Color("AccentOrange"))
        case .resolvedViaAPI:
            Text("TKGM")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color("SuccessGreen").opacity(0.15), in: Capsule())
                .foregroundStyle(Color("SuccessGreen"))
        }
    }
}

#Preview {
    NavigationStack {
        OfficialQueryHistoryView()
    }
}
