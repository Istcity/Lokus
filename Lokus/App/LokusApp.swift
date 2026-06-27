// MIT License
// Copyright (c) 2025 Sinan Nergiz — Lokus

import SwiftUI

@main
struct LokusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    _ = DeepLinkHandler.handle(url: url)
                }
        }
    }
}
