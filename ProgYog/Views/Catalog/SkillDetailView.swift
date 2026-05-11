//
//  SkillDetailView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillDetailView: View {
    let skill: CDAbsSkill

    @FetchRequest private var logs: FetchedResults<SetLog>

    init(skill: CDAbsSkill) {
        self.skill = skill
        _logs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: true)],
            predicate: NSPredicate(format: "absSkill == %@", skill)
        )
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Family", value: skill.family)
                LabeledContent("Series", value: skill.series)
                LabeledContent("Level", value: "\(skill.depth)")
                LabeledContent("Symmetrical", value: skill.symetrical ? "Yes" : "No")
            }

            if !skill.instructions.isEmpty {
                Section("Instructions") {
                    Text(skill.instructions)
                }
            }

            if logs.isEmpty {
                Section("Trend") {
                    Text("No sets logged yet for this skill.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Trend") {
                    SkillTrendChart(logs: Array(logs))
                }

                Section("Recent Sets") {
                    ForEach(logs.suffix(10).reversed(), id: \.id) { log in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.bold())
                            Text("RPT \(log.rpt) · RPE \(log.rpe) · RPD \(log.rpd) · reps \(log.reps) · \(log.decision)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(skill.name)
    }
}
