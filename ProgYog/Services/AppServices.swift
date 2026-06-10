//
//  AppServices.swift
//  ProgYog
//

import Foundation

@MainActor
final class AppServices: ObservableObject {
    let coreData: CoreDataService
    let heartRate: HeartRateService
    let audio: AudioCueService
    let theme: SwTheme
    let errorLog: ErrorLog
    let undo: UndoStack

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
        let hr = HeartRateService()
        hr.errorLog = log
        self.heartRate = hr
        self.audio = AudioCueService()
        self.theme = SwTheme()
        self.errorLog = log
        self.undo = UndoStack()
        log.info("App", "Launched")
    }
}
