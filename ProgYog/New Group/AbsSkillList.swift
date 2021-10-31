//
//  AbsSkillList.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//

import SwiftUI
import CoreData

struct AbsSkillList: View
{
    @State var rtr: AbsSkillListRtr
    @StateObject var vm: AbsSkillListVm
    
    var body: some View {
        NavigationView {
            List(vm.absSkills, id: \.self) { absSkill in
                Text("Series \(absSkill.series): \(absSkill.family) \(absSkill.depth): \(absSkill.name)")
            }
            .navigationTitle("ProgYog AbsSkills") //<- Causes "Unable to simultaneously satisfy constraints."
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


