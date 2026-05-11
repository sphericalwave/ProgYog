//
//  ProgYogApp.swift
//  ProgYog
//

import SwiftUI

@main
struct ProgYogApp: App {
    @StateObject private var services = AppServices()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(services)
        }
    }
}
