//
//  ProgYogApp.swift
//  ProgYog
//

import SwiftUI
import UIKit

@main
struct ProgYogApp: App {
    @StateObject private var services = AppServices()

    init() {
        // Make every scroll view in the app dismiss the keyboard
        // when the user drags it.
        UIScrollView.appearance().keyboardDismissMode = .interactive
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(services)
                .onAppear { KeyboardDismiss.installWindowTapRecognizer() }
        }
    }
}
