// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Kök içerik görünümü — uyarı ve ana sekmeler.
struct ContentView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false
    @ObservedObject private var router = AppRouter.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            MainTabView()
                .opacity(disclaimerAccepted ? 1 : 0)

            if !disclaimerAccepted {
                DisclaimerView()
            }
        }
        .task {
            bootstrapSDKs()
            consumeHandoff()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                consumeHandoff()
            }
        }
        .sheet(isPresented: $router.showFavorites) {
            NavigationStack {
                FavoritesView()
            }
        }
    }

    private func bootstrapSDKs() {
        AdMobService.shared.ensureSDKStarted()
        RevenueCatService.shared.configure()
        Task { @MainActor in
            await RevenueCatService.shared.checkPremiumStatus()
            await AdMobService.shared.preloadAds()
        }
    }

    private func consumeHandoff() {
        guard let handoff = AppGroupManager.shared.loadLocationHandoff() else { return }
        let age = Date().timeIntervalSince(handoff.timestamp)
        guard age < 3600 else {
            AppGroupManager.shared.clearLocationHandoff()
            return
        }

        LocationViewModel.shared.update(coordinate: handoff.coordinate, address: handoff.address)
        AppRouter.shared.openExplore(at: handoff.coordinate)
        AppGroupManager.shared.clearLocationHandoff()
    }
}

#Preview {
    ContentView()
}
