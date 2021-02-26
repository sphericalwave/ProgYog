//
//  AbsSkillList.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//

import SwiftUI
import CoreData

struct AbsSkillList: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(
        entity: CDAbsSkill.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CDAbsSkill.series, ascending: true),
            NSSortDescriptor(keyPath: \CDAbsSkill.depth, ascending: true),
            NSSortDescriptor(keyPath: \CDAbsSkill.family, ascending: true) //FIXME: Can i sort by family.order?
        ]
    ) var absSkills: FetchedResults<CDAbsSkill>
    
    var body: some View {
        List(absSkills, id: \.self) { absSkill in
            Text("Series \(absSkill.series): \(absSkill.family) \(absSkill.depth): \(absSkill.name)")
        }
    }
}


