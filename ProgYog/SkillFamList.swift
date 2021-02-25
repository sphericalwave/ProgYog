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
        entity: CDSkillFamily.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CDSkillFamily.series, ascending: true),
            NSSortDescriptor(keyPath: \CDSkillFamily.order, ascending: true)
        ]
    ) var skillFamilys: FetchedResults<CDSkillFamily>
    
    var body: some View {
        List(skillFamilys, id: \.self) { skillFam in
            Text("\(skillFam.series)\(skillFam.order) \(skillFam.name)")
        }
    }
}
