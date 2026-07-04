//
//  AppServices.swift
//  ProgYog
//

import Foundation
import WorkoutAudioKit

@MainActor
final class AppServices: ObservableObject {
    let coreData: CoreDataService
    let theme: SwTheme
    let errorLog: ErrorLog
    let undo: UndoStack
    let stats: WorkoutStatsStore

    private(set) lazy var heartRate: HeartRateService = {
        let hr = HeartRateService()
        hr.errorLog = self.errorLog
        return hr
    }()

    private(set) lazy var audio: AudioCueService = AudioCueService()

    init(inMemory: Bool = false) {
        let log = ErrorLog()
        let cd = CoreDataService(inMemory: inMemory)
        cd.attach(errorLog: log)
        if !inMemory {
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
        log.info("App", "Launched")
    }
}
