//
//  ProgYogApp.swift
//  ProgYog
//

import SwiftUI
import WorkoutSyncKit
import SwKeyboard
#if os(iOS)
import UIKit
#endif

@main
struct ProgYogApp: App {
    @StateObject private var services = AppServices()

    init() {
        // ProgYog's calendar color predates WorkoutSyncKit's blue default.
        WorkoutCalendarConfig.defaultColorHex = "#FF9F0A"
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
                    .onAppear { KeyboardDismissal.installTapOutsideDismissal() }
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
