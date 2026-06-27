// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import CoreLocation
import Foundation

/// `lokus://` deep link ayrıştırıcısı.
enum DeepLinkHandler {
    static func handle(url: URL) -> Bool {
        guard url.scheme?.lowercased() == "lokus" else { return false }

        let host = (url.host ?? url.pathComponents.dropFirst().first ?? "").lowercased()
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let lat = params.first(where: { $0.name == "lat" })?.value.flatMap(Double.init)
        let lon = params.first(where: { $0.name == "lon" })?.value.flatMap(Double.init)
        let coordinate: CLLocationCoordinate2D? = {
            guard let lat, let lon else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }()

        Task { @MainActor in
            switch host {
            case "kesfet", "map", "explore":
                if let coordinate {
                    AppRouter.shared.openExplore(at: coordinate)
                    LocationViewModel.shared.update(coordinate: coordinate, address: "Deep link konumu")
                } else {
                    AppRouter.shared.selectedTab = .explore
                }
            case "fizibilite", "roi":
                AppRouter.shared.openROI(at: coordinate)
                if let coordinate {
                    LocationViewModel.shared.update(coordinate: coordinate, address: "Deep link konumu")
                }
            case "favoriler", "favorites":
                AppRouter.shared.openFavoritesList()
            case "tapu":
                AppRouter.shared.selectedTab = .tapu
            default:
                AppRouter.shared.selectedTab = .explore
            }
        }

        return true
    }

    static func shareURL(for coordinate: CLLocationCoordinate2D, tab: AppTab = .explore) -> URL {
        let host: String
        switch tab {
        case .explore: host = "kesfet"
        case .roi: host = "fizibilite"
        default: host = "kesfet"
        }
        var components = URLComponents()
        components.scheme = "lokus"
        components.host = host
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.5f", coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(format: "%.5f", coordinate.longitude))
        ]
        return components.url ?? URL(string: "lokus://kesfet")!
    }
}
