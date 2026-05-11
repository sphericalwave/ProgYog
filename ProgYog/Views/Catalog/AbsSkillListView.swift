//
//  AbsSkillListView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct AbsSkillListView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "series", ascending: true),
            NSSortDescriptor(key: "family", ascending: true),
            NSSortDescriptor(key: "depth", ascending: true),
        ]
    ) private var skills: FetchedResults<CDAbsSkill>

    var body: some View {
        List(skills, id: \.self) { skill in
            NavigationLink(value: skill.objectID) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.name).font(.body)
                    Text("\(skill.series) · \(skill.family) · depth \(skill.depth)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("All Skills")
        .navigationDestination(for: NSManagedObjectID.self) { id in
            if let skill = skills.first(where: { $0.objectID == id }) {
                SkillDetailView(skill: skill)
            }
        }
    }
}
