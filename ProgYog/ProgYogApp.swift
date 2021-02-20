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
        print("WTF")
    }
    
    var body: some Scene {
        WindowGroup {
            //SeriesList()
            TestTabs()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                //.environment(\.managedObjectContext, data.persistentContainer.viewContext)
        }
        .onChange(of: scenePhase) { _ in
            persistenceController.save()
        }
    }
}

struct TestTabs: View {
    
    @State private var tab: Int = 0
    @Environment(\.managedObjectContext) var managedObjectContext //Do i need this if it's not used here?
    
    var body: some View {
        TabView(selection: $tab) {
            SeriesList()
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("Main")
                }
            
            AbsSkillList()
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("AbsSkills")
                }
        }
    }
}

import CoreData

struct AbsSkillList: View {
    @Environment(\.managedObjectContext) var managedObjectContext
//    var absSkills: FetchRequest<AbsSkill>
//
//    @FetchRequest(entity: AbsSkill.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \AbsSkill.series, ascending: true), NSSortDescriptor(keyPath: \AbsSkill.depth, ascending: false)])
    
    @FetchRequest(
        entity: AbsSkill.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AbsSkill.name, ascending: true),
            NSSortDescriptor(keyPath: \AbsSkill.depth, ascending: false)
        ]
    ) var absSkills: FetchedResults<AbsSkill>

    var body: some View {
        //Text("AbsSkills")

        List(absSkills, id: \.self) { absSkill in
            Text(absSkill.name ?? "Unknown")
        }
    }
}
