//
//  SkillFamList.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-23.
//

import SwiftUI
import CoreData

struct SkillFamList: View
{
    @State var rtr: SkillFamListRtr
    @StateObject var vm: SkillFamListVm
    
    var body: some View {
        NavigationView {
            List(vm.skillFamilies, id: \.self) { skillFam in
                Text("\(skillFam.series)\(skillFam.order) \(skillFam.name)")
            }
            .navigationTitle("ProgYog AbsSkills")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
