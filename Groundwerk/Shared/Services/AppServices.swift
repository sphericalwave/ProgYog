//
//  AppServices.swift
//  Groundwerk
//

import Foundation
import WorkoutAudioKit
import HeartRateKit
import AudioClipKit
import DiagnosticsKit

@MainActor
final class AppServices: ObservableObject {
    let coreData: CoreDataService
    let theme: SwTheme
    let errorLog: ErrorLog
    let undo: UndoStack
    let stats: WorkoutStatsStore

    private(set) lazy var heartRate = HeartRateMonitor()

    private(set) lazy var audio: AudioCueService = AudioCueService()

    /// - Parameter seedsCatalog: false on a device that should take its
    ///   catalog from CloudKit only (the Mac). The JSON seed has no dedupe,
    ///   so seeding a second device would sync a duplicate catalog to every
    ///   other device. The legacy one-time migrations are skipped too: they
    ///   only fix pre-CloudKit local data.
    init(inMemory: Bool = false, seedsCatalog: Bool = true) {
        let log = ErrorLog()
        let cd = CoreDataService(inMemory: inMemory)
        cd.attach(errorLog: log)
        if inMemory {
            // UI tests need the catalog to navigate; the UserDefaults seed
            // gate persists across launches regardless of store, so a
            // fresh in-memory container must force-seed instead.
            if ProcessInfo.processInfo.arguments.contains("-UI-TESTING-MOCK-WORKOUT") {
                cd.seedMockWorkout()
            } else {
                cd.forceSeed()
            }
        } else if seedsCatalog {
            cd.seedIfNeeded()
            cd.mergeLegacyNotesIfNeeded()
            cd.renameHoldToRepeatIfNeeded()
            cd.migrateSkillPhotosIfNeeded()
        }
        self.coreData = cd
        self.stats = WorkoutStatsStore(container: cd.container)
        self.theme = SwTheme()
        self.errorLog = log
        self.undo = UndoStack()
        AudioSessionConfigurator.log = { [weak log] in log?.info("AudioSession", $0) }
        AudioSessionHealthMonitor.shared.start()
        log.info("App", "Launched")
    }
}
