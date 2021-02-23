//
//  ProgressiveYogApp.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI

@main
struct ProgYogApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    var persistenceController = PersistenceController.shared

    init() {
        persistenceController.seedDB()
        //persistenceController.firstLaunch() //TODO: Reinstate
    }
    
    var body: some Scene {
        WindowGroup {
            TestTabs()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}



