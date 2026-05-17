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
            if isProduction {
                RootView()
                    .environmentObject(services)
                    .onAppear { KeyboardDismiss.installWindowTapRecognizer() }
            }
            // else: empty WindowGroup — unit tests build no view tree,
            // so the lazy AppServices @StateObject is never constructed.
        }
    }

    // qualitycoding.org/bypass-swiftui-app-launch-unit-testing
    // false under in-process unit tests (XCTestCase linked) → skip launch.
    // UI tests run out-of-process so XCTestCase is absent → true → real app.
    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
