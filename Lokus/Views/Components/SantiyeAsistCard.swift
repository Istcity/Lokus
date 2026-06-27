// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı

import SwiftUI

/// Şantiye Asist entegrasyon kartı — maliyet paylaşımı ve uygulama bağlantısı.
struct SantiyeAsistCard: View {
    let costs: ConstructionCosts?
    let isSelected: Bool
    let onRefresh: () -> Void
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Şantiye Asist", systemImage: "hammer.fill")
                    .font(.headline)
                    .foregroundStyle(Color("AccentOrange"))
                Spacer()
                if isSelected {
                    Text("Aktif")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("SuccessGreen").opacity(0.2), in: Capsule())
                        .foregroundStyle(Color("SuccessGreen"))
                }
            }

            if let costs {
                Text("Güncel inşaat maliyetleri paylaşıldı · \(costs.lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    costRow("Beton", value: costs.concreteCostPerM3, unit: "₺/m³")
                    costRow("Demir", value: costs.steelCostPerTon, unit: "₺/ton")
                    costRow("İşçilik", value: costs.laborCostPerHour, unit: "₺/saat")
                    costRow("İskele", value: costs.scaffoldCostPerM2, unit: "₺/m²")
                }

                Text("Türetilmiş maliyet: \(costs.derivedBuildingCostPerM2.formatted(.number.precision(.fractionLength(0)))) ₺/m²")
                    .font(.footnote.bold())

                HStack {
                    Button("Bu Maliyetleri Kullan", action: onSelect)
                        .buttonStyle(.borderedProminent)
                        .tint(Color("AccentOrange"))
                    Button("Yenile", action: onRefresh)
                        .buttonStyle(.bordered)
                }
            } else {
                Text("Şantiye Asist'te maliyetlerinizi kaydedin; Lokus otomatik olarak okur.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(LokusError.santiyeAsistNotInstalled.errorDescription ?? "")
                    .font(.caption)
                    .foregroundStyle(Color("WarningAmber"))

                HStack {
                    Button {
                        openSantiyeAsist()
                    } label: {
                        Label("Şantiye Asist'i Aç", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentOrange"))

                    Button("Yeniden Dene", action: onRefresh)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func costRow(_ title: String, value: Double, unit: String) -> some View {
        GridRow {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value.formatted(.number.precision(.fractionLength(0)))) \(unit)")
                .font(.caption.bold())
        }
    }

    private func openSantiyeAsist() {
        if let schemeURL = URL(string: Constants.santiyeAsistURLScheme),
           UIApplication.shared.canOpenURL(schemeURL) {
            UIApplication.shared.open(schemeURL)
        } else if let storeURL = URL(string: Constants.santiyeAsistAppStoreURL) {
            UIApplication.shared.open(storeURL)
        }
    }
}
