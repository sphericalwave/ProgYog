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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: false)]
    ) private var setLogs: FetchedResults<SetLog>

    var body: some View {
        List(skills, id: \.self) { skill in
            NavigationLink(value: skill.objectID) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(skill.name).font(.body)
                        Text("\(skill.series) · \(skill.family) · level \(skill.depth)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    stats(for: skill)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("All Skills")
        .navigationDestination(for: NSManagedObjectID.self) { id in
            if let skill = skills.first(where: { $0.objectID == id }) {
                SkillDetailView(skill: skill)
            }
        }
    }

    @ViewBuilder
    private func stats(for skill: CDAbsSkill) -> some View {
        let logs = setLogs.filter { $0.absSkill == skill }
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(logs.count) \(logs.count == 1 ? "set" : "sets")")
                .font(.caption.bold())
                .monospacedDigit()
            if let last = logs.first?.loggedAt {
                Text(last.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("never")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
