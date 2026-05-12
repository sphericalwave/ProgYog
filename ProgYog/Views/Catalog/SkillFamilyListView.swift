//
//  SkillFamilyListView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillFamilyListView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "series", ascending: true),
            NSSortDescriptor(key: "order", ascending: true),
        ]
    ) private var families: FetchedResults<CDSkillFamily>

    var body: some View {
        List(families, id: \.self) { family in
            NavigationLink {
                SkillFamilyDetailView(family: family)
            } label: {
                HStack {
                    Text(family.series)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("\(family.order).")
                    Text(family.name)
                }
            }
        }
        .navigationTitle("Skill Families")
    }
}
