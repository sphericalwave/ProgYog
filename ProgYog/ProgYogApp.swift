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
            //SeriesList()
            TestTabs()
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
    @Environment(\.managedObjectContext) var moc
    //var absSkills: FetchRequest<AbsSkill>

    var body: some View {
        Text("AbsSkills")
    }
}
