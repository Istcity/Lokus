// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import SwiftUI
import UIKit

/// Köy bilgilerini cam efektli alt panelde gösterir.
struct BottomSheetView: View {
    let village: Village
    let coordinate: CLLocationCoordinate2D
    var settlement: ResolvedSettlement?
    var nearestFault: (fault: FaultLine, distanceKm: Double)?
    var tkgmLookup: TKGMParcelResult?
    var onDismiss: (() -> Void)?
    var onZoningUpdated: (() -> Void)?

    @ObservedObject private var favorites = FavoritesStore.shared
    @State private var showZoningSheet = false
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var pdfURL: URL?
    @State private var showPDFShare = false
    @State private var savedToast = false

    private var isFavorite: Bool {
        favorites.contains(name: village.name, district: settlement?.districtName ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerRow
                locationMeta
                priceRow
                ZoningInfoRow(zoning: village.zoning, showDisclaimer: true)
                InfrastructureRow(infra: village.infrastructure)

                if let nearestFault {
                    faultRow(nearestFault)
                }

                if !village.notes.isEmpty {
                    Text(village.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }

                OfficialQueryActionsView(
                    coordinate: coordinate,
                    settlement: settlement,
                    geoResult: nil,
                    tkgmLookup: tkgmLookup,
                    showParcel: true,
                    showZoning: true
                )

                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.visible)
        .overlay(alignment: .top) {
            if savedToast {
                Text("Favorilere eklendi")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("SuccessGreen").opacity(0.9), in: Capsule())
                    .foregroundStyle(.white)
                    .offset(y: -20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showZoningSheet) {
            ZoningOverrideSheet(
                coordinate: coordinate,
                villageName: village.name,
                zoning: village.zoning,
                existing: ParcelZoningStore.shared.override(for: coordinate)
            ) { override in
                ParcelZoningStore.shared.save(override)
                onZoningUpdated?()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        .sheet(isPresented: $showPDFShare) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
    }

    private var headerRow: some View {
        HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
            Spacer()
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(Color("AccentOrange"))
            }
            Button { onDismiss?() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var locationMeta: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(village.name)
                    .font(.title2.bold())
                    .foregroundStyle(Color("TextPrimary"))
                settlementLine
            }
            Spacer(minLength: 8)
            LokusBrandView(style: .compact)
        }
    }

    @ViewBuilder
    private var settlementLine: some View {
        if let settlement {
            HStack(spacing: 6) {
                Image(systemName: settlement.isNeighborhood ? "building.2" : "tree")
                Text("\(settlement.districtName), \(settlement.provinceName)")
                    .font(.caption)
                if let pop = settlement.officialPopulation {
                    Text("· \(pop.formatted()) kişi")
                        .font(.caption2)
                }
                Spacer()
                Text(settlement.dataSource.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color("AccentOrange").opacity(0.15), in: Capsule())
            }
            .foregroundStyle(.secondary)
        }
    }

    private var priceRow: some View {
        HStack(spacing: 20) {
            PriceCard(label: "Konut m²", value: village.housePricePerM2, suffix: "₺")
            PriceCard(label: "Arsa m²", value: village.landPricePerM2, suffix: "₺")
        }
    }

    private func faultRow(_ info: (fault: FaultLine, distanceKm: Double)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(Color("DangerRed"))
            VStack(alignment: .leading, spacing: 2) {
                Text(info.fault.name)
                    .font(.caption.bold())
                Text(String(format: "%.1f km mesafede · Risk: %@", info.distanceKm, RiskLevel.from(distanceKm: info.distanceKm).rawValue))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color("DangerRed").opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            NavigationLink {
                ROIAnalysisView(preloadedVillage: village)
            } label: {
                Text("Fizibilite Analizi →")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentOrange"))

            HStack(spacing: 8) {
                Button {
                    showZoningSheet = true
                } label: {
                    Label("Çap Gir", systemImage: "doc.text")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    exportPDF()
                } label: {
                    Label("PDF", systemImage: "square.and.arrow.up")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 8) {
                Button {
                    shareDeepLink()
                } label: {
                    Label("Paylaş", systemImage: "link")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    sendToSantiyeAsist()
                } label: {
                    Label("Şantiye Asist", systemImage: "hammer")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func toggleFavorite() {
        guard let settlement else { return }
        if isFavorite { return }
        favorites.add(from: settlement, coordinate: coordinate)
        withAnimation { savedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { savedToast = false }
        }
    }

    private func shareDeepLink() {
        shareURL = DeepLinkHandler.shareURL(for: coordinate)
        showShareSheet = true
    }

    private func sendToSantiyeAsist() {
        AppGroupManager.shared.saveLocationHandoff(
            coordinate: coordinate,
            address: LocationViewModel.shared.formattedAddress,
            villageName: village.name
        )
        AppRouter.shared.openROI(at: coordinate)
        if let schemeURL = URL(string: Constants.santiyeAsistURLScheme),
           UIApplication.shared.canOpenURL(schemeURL) {
            UIApplication.shared.open(schemeURL)
        }
    }

    private func exportPDF() {
        do {
            pdfURL = try RegionReportGenerator().generateRegionReport(
                village: village,
                settlement: settlement,
                coordinate: coordinate,
                roiResult: nil,
                roiInputs: nil
            )
            showPDFShare = true
        } catch {}
    }
}

/// Fiyat kartı bileşeni.
struct PriceCard: View {
    let label: String
    let value: Double
    let suffix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("TextSecondary"))
            NumberTickerView(targetValue: value, prefix: "", suffix: " \(suffix)", duration: 1.2)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// İmar bilgisi satırı — TAKS/KAKS açılımlarıyla.
struct ZoningInfoRow: View {
    let zoning: ZoningInfo
    var showDisclaimer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("İmar Durumu")
                    .font(.subheadline.bold())
                Spacer()
                if showDisclaimer {
                    Text("Tahmini")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("WarningAmber").opacity(0.2), in: Capsule())
                        .foregroundStyle(Color("WarningAmber"))
                }
            }

            HStack(spacing: 8) {
                Image(systemName: zoning.statusIcon)
                    .foregroundStyle(zoning.statusColor)
                Text(zoning.status.rawValue)
                    .font(.subheadline.bold())
                Spacer()
                Text(zoning.maxFloors)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(zoning.statusColor.opacity(0.15), in: Capsule())
            }

            HStack(alignment: .top, spacing: 16) {
                zoningMetric(
                    abbreviation: "TAKS",
                    fullName: ZoningInfo.taksFullName,
                    value: zoning.taks
                )
                zoningMetric(
                    abbreviation: "KAKS",
                    fullName: ZoningInfo.kaksFullName,
                    value: zoning.kaks
                )
            }

            if showDisclaimer {
                Text("Parsel bazlı imar için belediyeden çap veya e-Plan sorgulayın.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func zoningMetric(abbreviation: String, fullName: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(abbreviation) \(value, format: .number.precision(.fractionLength(2)))")
                .font(.footnote.bold())
            Text(fullName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Altyapı ikon satırı.
struct InfrastructureRow: View {
    let infra: Infrastructure

    var body: some View {
        HStack(spacing: 16) {
            InfraIcon(name: "bolt.fill", active: infra.electricity, label: "Elektrik")
            InfraIcon(name: "drop.fill", active: infra.water, label: "Su")
            InfraIcon(name: "flame.fill", active: infra.naturalGas, label: "Gaz")
            InfraIcon(name: "road.lanes", active: infra.road, label: "Yol")
            InfraIcon(name: "wifi", active: infra.internet, label: "İnternet")
        }
    }
}

struct InfraIcon: View {
    let name: String
    let active: Bool
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: name)
                .foregroundStyle(active ? Color("SuccessGreen") : Color("TextSecondary").opacity(0.4))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
