// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import SwiftUI
import UIKit

/// Resmi kurum web sorguları — veri yoksa veya doğrulama için.
struct OfficialQueryActionsView: View {
    let coordinate: CLLocationCoordinate2D
    var settlement: ResolvedSettlement?
    var geoResult: LocationAnalysisResult?
    var tkgmLookup: TKGMParcelResult?
    var showParcel: Bool = true
    var showZoning: Bool = true
    var showInfrastructure: Bool = false

    @ObservedObject private var queryLog = OfficialQueryLogStore.shared
    @State private var safariURL: URL?
    @State private var showSafari = false
    @State private var toastMessage: String?

    private var needsParcel: Bool {
        geoResult?.parcel == nil
    }

    private var needsZoning: Bool {
        geoResult?.zoning == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Resmi Kaynaklarda Sorgula", systemImage: "building.columns")
                    .font(.subheadline.bold())
                Spacer()
                if needsParcel || needsZoning {
                    Text("Veri eksik")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("WarningAmber").opacity(0.2), in: Capsule())
                        .foregroundStyle(Color("WarningAmber"))
                }
            }

            if let tkgm = tkgmLookup, needsParcel {
                tkgmResolvedBanner(tkgm)
            }

            if showParcel && (needsParcel || tkgmLookup != nil) {
                queryButton(
                    title: "TKGM Parsel Sorgu",
                    subtitle: parcelSubtitle,
                    icon: "map",
                    kind: .parcel
                ) {
                    openParcelQuery()
                }
            }

            if showZoning && needsZoning {
                queryButton(
                    title: "İmar / e-Plan Portalı",
                    subtitle: zoningSubtitle,
                    icon: "building.2",
                    kind: .zoning
                ) {
                    openZoningQuery()
                }
            }

            if showInfrastructure {
                queryButton(
                    title: "Altyapı Haritası (OSM)",
                    subtitle: "Açık sokak ve altyapı verisi",
                    icon: "bolt",
                    kind: .infrastructure
                ) {
                    openInfrastructureQuery()
                }
            }

            Text("Lokus resmi belge yerine geçmez. Sorgu kaydı cihazınızda saklanır.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color("AccentOrange").opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showSafari) {
            if let safariURL {
                SafariSheet(url: safariURL)
                    .ignoresSafeArea()
            }
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .offset(y: -28)
                    .transition(.opacity)
            }
        }
    }

    private var parcelSubtitle: String {
        let link = OfficialQueryLinks.tkgmParcelQuery(coordinate: coordinate, tkgm: tkgmLookup)
        return link.subtitle
    }

    private var zoningSubtitle: String {
        let link = OfficialQueryLinks.zoningPortal(
            provincePlate: settlement?.provincePlate,
            provinceName: settlement?.provinceName,
            coordinate: coordinate
        )
        return link.subtitle
    }

    @ViewBuilder
    private func tkgmResolvedBanner(_ tkgm: TKGMParcelResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TKGM koordinat sorgusu")
                .font(.caption.bold())
                .foregroundStyle(Color("SuccessGreen"))
            Text("\(tkgm.ilAd) / \(tkgm.ilceAd) · \(tkgm.mahalleAd)")
                .font(.footnote)
            Text("Ada \(tkgm.adaNo) / Parsel \(tkgm.parselNo)")
                .font(.footnote.bold())
            if let alan = tkgm.alan {
                Text("Alan: \(alan) m²")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("SuccessGreen").opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    private func queryButton(
        title: String,
        subtitle: String,
        icon: String,
        kind: OfficialQueryKind,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color("AccentOrange"))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.footnote.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "safari")
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func openParcelQuery() {
        let link = OfficialQueryLinks.tkgmParcelQuery(coordinate: coordinate, tkgm: tkgmLookup)
        let recordId = queryLog.recordPending(
            kind: .parcel,
            coordinate: coordinate,
            settlement: settlement,
            tkgm: tkgmLookup
        )
        UIPasteboard.general.string = link.clipboard
        showToast("TKGM koordinat sorgusu açılıyor")
        queryLog.markOpened(id: recordId, url: link.url)
        safariURL = link.url
        showSafari = true
    }

    private func openZoningQuery() {
        let link = OfficialQueryLinks.zoningPortal(
            provincePlate: settlement?.provincePlate,
            provinceName: settlement?.provinceName,
            coordinate: coordinate
        )
        let recordId = queryLog.recordPending(kind: .zoning, coordinate: coordinate, settlement: settlement)
        UIPasteboard.general.string = link.clipboard
        showToast("Koordinatlar panoya kopyalandı")
        queryLog.markOpened(id: recordId, url: link.url)
        safariURL = link.url
        showSafari = true
    }

    private func openInfrastructureQuery() {
        let url = OfficialQueryLinks.infrastructurePortal(coordinate: coordinate)
        let recordId = queryLog.recordPending(kind: .infrastructure, coordinate: coordinate, settlement: settlement)
        queryLog.markOpened(id: recordId, url: url)
        safariURL = url
        showSafari = true
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }
}
