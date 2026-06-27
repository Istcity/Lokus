// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus Gayrimenkul Konum Radarı
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
// WARRANTY OF ANY KIND.

import SwiftUI

/// Ödüllü reklam veya Premium ile kilidi açılan özellik kapısı.
struct FeatureGateView<Content: View>: View {
    let featureName: String
    let content: Content

    @AppStorage(Constants.lastUnlockTimestampKey) private var lastUnlockTimestamp: Double = 0
    @ObservedObject private var revenueCat = RevenueCatService.shared
    @ObservedObject private var adMob = AdMobService.shared
    @State private var isLoadingAd = false
    @State private var showError = false
    @State private var errorText = ""

    private var isUnlockedByAd: Bool {
        RewardedUnlockStatus.isActive
    }

    private var remainingUnlockText: String? {
        RewardedUnlockStatus.formattedRemaining
    }

    private var hasAccess: Bool {
        PremiumAccess.hasFeatureAccess(isSubscribed: revenueCat.isPremium, unlockedByAd: isUnlockedByAd)
    }

    init(featureName: String, @ViewBuilder content: () -> Content) {
        self.featureName = featureName
        self.content = content()
    }

    var body: some View {
        if hasAccess {
            content
        } else {
            VStack(spacing: 16) {
                LokusBrandView(style: .compact)
                Image(systemName: "lock.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color("AccentOrange"))
                Text("\(featureName) kilitli")
                    .font(.headline)
                Text("Tam analiz için ödüllü reklam izleyin (\(Int(Constants.unlockDurationHours)) saat geçerli) veya Premium'a geçin.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let remaining = remainingUnlockText {
                    Text("Son izleme süresi: \(remaining) kaldı")
                        .font(.caption2)
                        .foregroundStyle(Color("WarningAmber"))
                }

                Button {
                    watchAd()
                } label: {
                    if isLoadingAd {
                        ProgressView()
                    } else {
                        Text("Reklam İzle ve Aç")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentOrange"))
                .disabled(isLoadingAd)
            }
            .padding()
            .task {
                await adMob.preloadAds()
            }
            .alert("Reklam", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorText)
            }
        }
    }

    private func watchAd() {
        isLoadingAd = true
        Task {
            let rewarded = await adMob.showRewardedAd()
            isLoadingAd = false
            if rewarded {
                lastUnlockTimestamp = Date().timeIntervalSince1970
            } else {
                errorText = "Reklam yüklenemedi. Lütfen tekrar deneyin."
                showError = true
                await adMob.loadRewardedAd()
            }
        }
    }
}

#Preview {
    FeatureGateView(featureName: "Bölge Analizi") {
        Text("Açık içerik")
    }
}
