//
//  GroundwerkApp.swift
//  Groundwerk (macOS)
//

import SwiftUI
import WorkoutSyncKit

@main
struct GroundwerkApp: App {
    // UI tests pass -UI-TESTING so they run against an in-memory store
    // instead of the real CloudKit-backed database. The Mac never seeds
    // the catalog: it arrives from the iPhone via CloudKit (no dedupe).
    @StateObject private var services = AppServices(
        inMemory: ProcessInfo.processInfo.arguments.contains("-UI-TESTING"),
        seedsCatalog: false
    )

    init() {
        // Groundwerk's calendar color predates WorkoutSyncKit's blue default.
        WorkoutCalendarConfig.defaultColorHex = "#FF9F0A"
    }

    var body: some Scene {
        WindowGroup {
            if isProduction {
                RootView()
                    .environmentObject(services)
                    .frame(minWidth: 820, minHeight: 560)
            }
            // else: empty WindowGroup — unit tests build no view tree.
        }
        .commands {
            // Mac stand-in for iOS shake-to-undo (deletes only).
            CommandGroup(after: .undoRedo) {
                Button("Undo Last Delete") { _ = services.undo.undoLast() }
                    .keyboardShortcut("z", modifiers: [.command, .option])
            }
        }
    }

    // false under in-process unit tests → skip launch.
    private var isProduction: Bool {
        NSClassFromString("XCTestCase") == nil
    }
}
