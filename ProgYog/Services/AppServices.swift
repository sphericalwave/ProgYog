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

    init(inMemory: Bool = false) {
        let log = ErrorLog()
        let cd = CoreDataService(inMemory: inMemory)
        cd.attach(errorLog: log)
        if !inMemory {
            cd.seedIfNeeded()
            cd.mergeLegacyNotesIfNeeded()
        }
        self.coreData = cd
        let hr = HeartRateService()
        hr.errorLog = log
        self.heartRate = hr
        self.audio = AudioCueService()
        self.theme = SwTheme()
        self.errorLog = log
        log.info("App", "Launched")
    }
}
