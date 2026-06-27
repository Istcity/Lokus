// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import CoreLocation
import StoreKit
import SwiftUI
import UIKit

/// Kullanıcı profili ve premium abonelik yönetimi.
struct ProfileView: View {
    @ObservedObject private var revenueCat = RevenueCatService.shared
    @State private var statusMessage: String?

    var body: some View {
        List {
            Section {
                LokusBrandView(style: .header)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }

            Section("Hesap") {
                LabeledContent("Geliştirici", value: "Sinan Nergiz")
                LabeledContent("Uygulama", value: "Lokus")
                LabeledContent("Bundle ID", value: Constants.bundleID)
                LabeledContent("Sürüm", value: appVersion)
            }

            Section("Abonelik") {
                if PremiumAccess.bypassEnabled {
                    Label("Test modu — tüm özellikler açık", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Color("SuccessGreen"))
                    Text("Ödüllü reklam ve Premium kapıları test aşamasında devre dışı.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !revenueCat.isConfigured {
                    Label("RevenueCat yapılandırılmamış", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Color("WarningAmber"))
                    Text("Secrets.plist dosyasına RevenueCat public API anahtarınızı ekleyin (appl_...).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Durum")
                    Spacer()
                    if revenueCat.hasPremiumAccess {
                        Label(PremiumAccess.bypassEnabled ? "Test (Premium)" : "Premium", systemImage: "crown.fill")
                            .foregroundStyle(Color("AccentOrange"))
                    } else {
                        Text("Ücretsiz")
                            .foregroundStyle(.secondary)
                    }
                }

                if let expiration = revenueCat.expirationDate, revenueCat.isPremium, !PremiumAccess.bypassEnabled {
                    LabeledContent("Yenileme") {
                        Text(expiration.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                if !revenueCat.hasPremiumAccess, let remaining = RewardedUnlockStatus.formattedRemaining {
                    LabeledContent("Reklam erişimi") {
                        Text("\(remaining) kaldı")
                            .foregroundStyle(Color("WarningAmber"))
                    }
                }

                if !revenueCat.hasPremiumAccess, let price = revenueCat.premiumPriceText {
                    LabeledContent("Lokus Premium Yıllık", value: price)
                }

                if !revenueCat.hasPremiumAccess, revenueCat.isConfigured {
                    Button {
                        purchasePremium()
                    } label: {
                        HStack {
                            Text("Lokus Premium Satın Al")
                            if let price = revenueCat.premiumPriceText {
                                Spacer()
                                Text(price).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(revenueCat.isLoading)
                }

                Button("Satın Alımları Geri Yükle") {
                    restorePurchases()
                }
                .disabled(revenueCat.isLoading || !revenueCat.isConfigured)

                if revenueCat.isPremium, !PremiumAccess.bypassEnabled {
                    Button("Aboneliği Yönet") {
                        manageSubscription()
                    }
                }

                if revenueCat.isLoading {
                    ProgressView()
                }
            }

            Section("Veriler") {
                NavigationLink {
                    FavoritesView()
                } label: {
                    HStack {
                        Label("Favori Bölgeler", systemImage: "star.fill")
                        Spacer()
                        Text("\(FavoritesStore.shared.favorites.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    OfficialQueryHistoryView()
                } label: {
                    HStack {
                        Label("Resmi Sorgu Geçmişi", systemImage: "doc.text.magnifyingglass")
                        Spacer()
                        Text("\(OfficialQueryLogStore.shared.records.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Label("Kısayollar: \"Son bölgeyi Lokus'ta aç\"", systemImage: "square.grid.2x2")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(AppConfiguration.geoAttributionText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Section("Premium Özellikler") {
                Label("Sınırsız bölge analizi", systemImage: "map")
                Label("PDF belge şablonları", systemImage: "doc.fill")
                Label("Reklamsız deneyim", systemImage: "nosign")
                Label("Çoklu karşılaştırma", systemImage: "square.stack.3d.up")
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .lokusNavigationBarLogo()
        .task {
            await revenueCat.checkPremiumStatus()
        }
        .refreshable {
            await revenueCat.checkPremiumStatus()
        }
        .lokusAdBanner()
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func purchasePremium() {
        Task {
            do {
                try await revenueCat.purchasePremium()
                statusMessage = revenueCat.isPremium
                    ? "Premium abonelik aktif!"
                    : "Satın alma tamamlanamadı."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await revenueCat.restorePurchases()
                statusMessage = revenueCat.isPremium
                    ? "Premium geri yüklendi."
                    : "Geri yüklenecek satın alım bulunamadı."
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }

    private func manageSubscription() {
        Task {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
                return
            }
            try? await AppStore.showManageSubscriptions(in: scene)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
