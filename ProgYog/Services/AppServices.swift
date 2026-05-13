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

    init(inMemory: Bool = false) {
        let cd = CoreDataService(inMemory: inMemory)
        if !inMemory {
            cd.seedIfNeeded()
            cd.mergeLegacyNotesIfNeeded()
        }
        self.coreData = cd
        self.heartRate = HeartRateService()
        self.audio = AudioCueService()
        self.theme = SwTheme()
    }
}
