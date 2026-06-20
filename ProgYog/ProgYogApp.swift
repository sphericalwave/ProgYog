//
//  ProgYogApp.swift
//  ProgYog
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct ProgYogApp: App {
    @StateObject private var services = AppServices()

    init() {
        #if os(iOS)
        UIScrollView.appearance().keyboardDismissMode = .interactive
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            if isProduction {
                RootView()
                    .environmentObject(services)
                    .onAppear { KeyboardDismiss.installWindowTapRecognizer() }
            }
            // else: empty WindowGroup — unit tests build no view tree,
            // so the lazy AppServices @StateObject is never constructed.
            #else
            MacRootView()
                .environmentObject(services)
            #endif
        }
    }

    #if os(iOS)
    // false under in-process unit tests → skip launch.
    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
    #endif
}
