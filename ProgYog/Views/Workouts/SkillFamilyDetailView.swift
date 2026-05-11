//
//  SkillFamilyDetailView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillFamilyDetailView: View {
    let family: CDSkillFamily

    private var skills: [CDAbsSkill] {
        let set = (family.absSkills as? Set<CDAbsSkill>) ?? []
        return set.sorted { $0.depth < $1.depth }
    }

    var body: some View {
        List(skills, id: \.self) { skill in
            NavigationLink {
                SkillDetailView(skill: skill)
            } label: {
                HStack {
                    Text("Level \(skill.depth)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(skill.name)
                }
            }
        }
        .navigationTitle(family.name)
    }
}
