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

    var body: some View {
        TabView(selection: $vm.tab) {
            rtr.progYogDash()
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("Main")
                }
            
            rtr.absProgYogSkills()
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("AbsSkills")
                }
            
            rtr.progYogSkillFamillies()
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("SkillFam")
                }
        }
    }
}
