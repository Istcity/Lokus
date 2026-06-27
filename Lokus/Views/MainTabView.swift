// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

/// Ana sekme navigasyonu.
struct MainTabView: View {
    @ObservedObject private var router = AppRouter.shared

    var body: some View {
        TabView(selection: $router.selectedTab) {
            MapRadarView()
                .tabItem { Label("Keşfet", systemImage: "map.fill") }
                .tag(AppTab.explore)

            NavigationStack {
                ROIAnalysisView()
            }
            .tabItem { Label("Fizibilite", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(AppTab.roi)

            NavigationStack {
                TapuAssistantView()
            }
            .tabItem { Label("Tapu & Hukuk", systemImage: "doc.text.magnifyingglass") }
            .tag(AppTab.tapu)

            NavigationStack {
                DocumentBuilderView()
            }
            .tabItem { Label("Belgeler", systemImage: "doc.badge.plus") }
            .tag(AppTab.documents)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profil", systemImage: "person.circle") }
            .tag(AppTab.profile)
        }
        .tint(Color("AccentOrange"))
    }
}

#Preview {
    MainTabView()
}
