// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// Uygulama sekmeleri.
enum AppTab: Int, Hashable, CaseIterable {
    case explore = 0
    case roi = 1
    case tapu = 2
    case documents = 3
    case profile = 4

    var title: String {
        switch self {
        case .explore: "Keşfet"
        case .roi: "Fizibilite"
        case .tapu: "Tapu & Hukuk"
        case .documents: "Belgeler"
        case .profile: "Profil"
        }
    }
}

/// Sekme yönlendirme ve deep link kuyruğu.
@MainActor
final class AppRouter: ObservableObject {
    static let shared = AppRouter()

    @Published var selectedTab: AppTab = .explore
    @Published var pendingCoordinate: CLLocationCoordinate2D?
    @Published var showFavorites = false
    @Published var showCompare = false

    private init() {}

    func openExplore(at coordinate: CLLocationCoordinate2D) {
        pendingCoordinate = coordinate
        selectedTab = .explore
    }

    func openROI(at coordinate: CLLocationCoordinate2D?) {
        if let coordinate {
            pendingCoordinate = coordinate
        }
        selectedTab = .roi
    }

    func openFavoritesList() {
        selectedTab = .profile
        showFavorites = true
    }
}
