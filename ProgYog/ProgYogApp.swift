//
//  ProgressiveYogApp.swift
//  ProgressiveYog
//
//  Created by Aaron Anthony on 2021-02-19.
//

import SwiftUI

@main
struct ProgYogApp: App {
    
    var data = ProgYogData() //TODO: Must call first launch

    init() {
        data.seedDB()
        print("WTF")
    }
    
    var body: some Scene {
        WindowGroup {
            //SeriesList()
            TestTabs()
                //.environment(\.managedObjectContext, data.persistentContainer.viewContext)
        }
    }
}

struct TestTabs: View {
    
    @State private var tab: Int = 0
    
    var body: some View {
        TabView(selection: $tab) {
            SeriesList()
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("Main")
                }
            
//            AbsSkillList()
//                .tabItem {
//                    Image(systemName: "bolt").imageScale(.large)
//                    Text("AbsSkills")
//                }
        }
    }
}

//import CoreData
//
//struct AbsSkillList: View {
//    @Environment(\.managedObjectContext) var moc
//    var absSkills: FetchRequest<AbsSkill>
//
//    @FetchRequest(entity: AbsSkill.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \AbsSkill.series, ascending: true), NSSortDescriptor(keyPath: \AbsSkill.depth, ascending: false)])
//
//    var body: some View {
//        //Text("AbsSkills")
//
//        List(absSkills, id: \.self) { absSkill in
//            Text(absSkill.name ?? "Unknown")
//        }
//    }
//}
