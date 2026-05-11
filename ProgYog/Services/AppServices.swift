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

    init() {
        let cd = CoreDataService()
        cd.seedIfNeeded()
        self.coreData = cd
        self.heartRate = HeartRateService()
        self.audio = AudioCueService()
        self.theme = SwTheme()
    }
}
