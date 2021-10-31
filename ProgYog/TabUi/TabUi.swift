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
                .tag(0)
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("Main")
                }
            
            rtr.absProgYogSkills()
                .tag(1)
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("AbsSkills")
                }
            
            rtr.progYogSkillFamillies()
                .tag(2)
                .tabItem {
                    Image(systemName: "bolt").imageScale(.large)
                    Text("SkillFam")
                }
        }
    }
}
