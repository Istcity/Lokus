// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Geo backend analiz sonucu bottom sheet.
struct LocationAnalysisSheet: View {
    let data: LocationAnalysisResult
    var settlement: ResolvedSettlement?
    var coordinate: CLLocationCoordinate2D?
    var tkgmLookup: TKGMParcelResult?
    var onDismiss: (() -> Void)?
    var onZoningUpdated: (() -> Void)?
    var showCachedBanner: Bool = false

    @ObservedObject private var favorites = FavoritesStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if showCachedBanner || data.cached == true {
                    Label("Önbellek verisi gösteriliyor", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(Color("WarningAmber"))
                }

                if let zoning = data.zoning {
                    GeoSectionCard(title: "İmar Durumu", icon: "building.2") {
                        GeoZoningDetailView(zoning: zoning)
                    }
                }

                if let parcel = data.parcel {
                    GeoSectionCard(title: "Parsel", icon: "map") {
                        GeoParcelDetailView(parcel: parcel)
                    }
                } else if let tkgm = tkgmLookup {
                    GeoSectionCard(title: "Parsel (TKGM)", icon: "map") {
                        TKGMParcelDetailView(result: tkgm)
                    }
                }

                if data.parcel == nil || data.zoning == nil, let coordinate {
                    OfficialQueryActionsView(
                        coordinate: coordinate,
                        settlement: settlement,
                        geoResult: data,
                        tkgmLookup: tkgmLookup,
                        showParcel: data.parcel == nil,
                        showZoning: data.zoning == nil
                    )
                }

                GeoSectionCard(title: "Altyapı", icon: "bolt.fill") {
                    InfrastructureGrid(infra: data.infrastructure)
                }

                GeoSectionCard(title: "Çevre Hizmetleri", icon: "mappin.and.ellipse") {
                    POIListView(pois: data.poi)
                }

                DataSourcesFooter(sources: data.dataSources)

                if let settlement, let coordinate {
                    legacyActions(settlement: settlement, coordinate: coordinate)
                }
            }
            .padding()
        }
        .scrollIndicators(.visible)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(settlement?.settlementName ?? data.parcel?.mahalle ?? "Konum Analizi")
                    .font(.title3.bold())
                if let settlement {
                    Text("\(settlement.districtName), \(settlement.provinceName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button { onDismiss?() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func legacyActions(settlement: ResolvedSettlement, coordinate: CLLocationCoordinate2D) -> some View {
        NavigationLink {
            ROIAnalysisView(preloadedVillage: settlement.village)
        } label: {
            Text("Fizibilite Analizi →")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("AccentOrange"))
    }
}

struct GeoSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct GeoZoningDetailView: View {
    let zoning: GeoZoningInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let level = zoning.confidenceLevel, level == .low {
                ConfidenceBadge(level: level)
            }
            if let note = zoning.planNotu {
                Text(note)
                    .font(.footnote)
            }
            HStack {
                if let taks = zoning.taks {
                    VStack(alignment: .leading) {
                        Text("TAKS \(taks, format: .number.precision(.fractionLength(2)))")
                            .font(.footnote.bold())
                        Text(ZoningInfo.taksFullName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let kaks = zoning.kaks {
                    VStack(alignment: .leading) {
                        Text("KAKS \(kaks, format: .number.precision(.fractionLength(2)))")
                            .font(.footnote.bold())
                        Text(ZoningInfo.kaksFullName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if let tur = zoning.yapilasmaTuru {
                Text("Tür: \(tur)")
                    .font(.caption)
            }
            if let kat = zoning.maxKat {
                Text(kat)
                    .font(.caption.bold())
            }
        }
    }
}

struct GeoParcelDetailView: View {
    let parcel: GeoParcelInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let level = parcel.confidenceLevel, level == .low {
                ConfidenceBadge(level: level)
            }
            if let ada = parcel.ada, let parsel = parcel.parsel {
                Text("Ada / Parsel: \(ada) / \(parsel)")
                    .font(.footnote.bold())
            }
            if let area = parcel.yuzolcum {
                Text("Yüzölçümü: \(area.formatted()) m²")
                    .font(.footnote)
            }
            if let ozet = parcel.malikOzet {
                Text(ozet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TKGMParcelDetailView: View {
    let result: TKGMParcelResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(result.ilAd) / \(result.ilceAd) · \(result.mahalleAd)")
                .font(.footnote)
            Text("Ada / Parsel: \(result.adaParselLabel)")
                .font(.footnote.bold())
            if let alan = result.alan {
                Text("Alan: \(alan) m²")
                    .font(.footnote)
            }
            if let nitelik = result.nitelik {
                Text(nitelik)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Kaynak: TKGM MEGSİS (koordinat sorgusu)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

struct ConfidenceBadge: View {
    let level: GeoConfidenceLevel

    var body: some View {
        Text(level.label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color("WarningAmber").opacity(0.2), in: Capsule())
            .foregroundStyle(Color("WarningAmber"))
    }
}

import CoreLocation
