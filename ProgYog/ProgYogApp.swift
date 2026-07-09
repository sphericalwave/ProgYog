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
    // UI tests pass -UI-TESTING so they run against an in-memory store —
    // XCUIApplication().launch() runs the real app process against the real
    // on-disk CloudKit-backed database otherwise, and a UI test would be
    // able to write/delete real logged workouts.
    @StateObject private var services = AppServices(
        inMemory: ProcessInfo.processInfo.arguments.contains("-UI-TESTING")
    )

    init() {
        // ProgYog's calendar color predates WorkoutSyncKit's blue default.
        WorkoutCalendarConfig.defaultColorHex = "#FF9F0A"
        #if os(iOS)
        UIScrollView.appearance().keyboardDismissMode = .interactive
        #endif
        if ProcessInfo.processInfo.arguments.contains("-UI-TESTING") {
            // Onboarding's fullScreenCover gates on this UserDefaults flag,
            // which (like the seed-version gate) persists across launches
            // regardless of store — would block every UI test on a
            // simulator that hasn't seen onboarding yet.
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }
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
