// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import AppIntents
import CoreLocation

/// Son görüntülenen bölgeyi Lokus'ta açar.
struct OpenLastRegionIntent: AppIntent {
    static var title: LocalizedStringResource = "Son Bölgeyi Aç"
    static var description = IntentDescription("Lokus'ta son baktığınız bölgeyi açar.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        guard let defaults = UserDefaults(suiteName: Constants.appGroupID) else {
            return .result()
        }
        let lat = defaults.double(forKey: AppGroupManager.Keys.lastLatitude)
        let lon = defaults.double(forKey: AppGroupManager.Keys.lastLongitude)
        guard lat != 0, lon != 0 else { return .result() }

        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        await MainActor.run {
            AppRouter.shared.openExplore(at: coordinate)
        }
        return .result()
    }
}

/// Fizibilite sekmesini açar.
struct OpenFeasibilityIntent: AppIntent {
    static var title: LocalizedStringResource = "Fizibilite Analizi"
    static var description = IntentDescription("Lokus fizibilite ekranını açar.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppRouter.shared.selectedTab = .roi
        }
        return .result()
    }
}

/// Kısayollar için uygulama kısayolları sağlayıcısı.
struct LokusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenLastRegionIntent(),
            phrases: [
                "Son bölgeyi \(.applicationName)'ta aç",
                "\(.applicationName) son bölge"
            ],
            shortTitle: "Son Bölge",
            systemImageName: "map.fill"
        )
        AppShortcut(
            intent: OpenFeasibilityIntent(),
            phrases: [
                "\(.applicationName) fizibilite",
                "Fizibilite \(.applicationName)"
            ],
            shortTitle: "Fizibilite",
            systemImageName: "chart.line.uptrend.xyaxis"
        )
    }
}
