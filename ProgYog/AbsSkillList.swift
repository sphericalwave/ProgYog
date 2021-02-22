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
        entity: AbsSkill.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \AbsSkill.name, ascending: true),
            NSSortDescriptor(keyPath: \AbsSkill.depth, ascending: false)
        ]
    ) var absSkills: FetchedResults<AbsSkill>

    var body: some View {
        List(absSkills, id: \.self) { absSkill in
            Text(absSkill.name ?? "Unknown")
        }
    }
}
