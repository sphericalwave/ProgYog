//
//  TestTabs.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//

import SwiftUI

struct TabUi: View
{
    @State var rtr: TabRtr
    @StateObject var vm: TabVm
    
    //@State private var tab: Int = 2
    @Environment(\.managedObjectContext) var managedObjectContext //TODO: Do i need this if it's not used here?
    
    var body: some View {
        TabView(selection: $vm.tab) {
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
            
            SkillFamList()
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("SkillFam")
                }
        }
    }
}
