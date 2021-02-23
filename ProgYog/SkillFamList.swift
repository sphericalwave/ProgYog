//
//  SkillFamList.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-23.
//

import SwiftUI
import CoreData

struct SkillFamList: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest(
        entity: SkillFamily.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \SkillFamily.name, ascending: true),
            NSSortDescriptor(keyPath: \SkillFamily.order, ascending: true)
        ]
    ) var skillFamilys: FetchedResults<SkillFamily>
    
    var body: some View {
        List(skillFamilys, id: \.self) { skillFam in
            Text("\(skillFam.name): \(skillFam.order)")
        }
    }
}
