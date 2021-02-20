//
//  ProgressiveYogApp.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI

@main
struct ProgYogApp: App {

    init() {
        var data = ProgYogData() //TODO: Must call first launch
        data.seedDB()
        print("WTF")
    }

    var body: some Scene {
        WindowGroup {
            SeriesList()
        }
    }
}
