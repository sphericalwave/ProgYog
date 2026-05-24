//
//  WorkoutFamilyDetailView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutFamilyDetailView: View {
    @ObservedObject var session: Session
    let family: CDSkillFamily

    var body: some View {
        List {
            ForEach(roundGroups, id: \.round) { group in
                Section {
                    ForEach(group.logs, id: \.objectID) { log in
                        setRow(log)
                    }
                } header: {
                    HStack {
                        Text("Round \(group.round + 1)")
                        Spacer()
                        CompletionChip(
                            percent: CompletionScorer.roundFamilyPercent(
                                in: session, family: family, round: group.round
                            )
                        )
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(family.name)
    }

    private var familyLogs: [SetLog] {
        session.orderedSetLogs.filter { $0.absSkill?.skillFamily == family }
    }

    private var roundGroups: [(round: Int16, logs: [SetLog])] {
        let dict = Dictionary(grouping: familyLogs) { $0.roundIndex }
        return dict.keys.sorted().map { round in
            (round: round, logs: dict[round]!.sorted { $0.orderInRound < $1.orderInRound })
        }
    }

    @ViewBuilder
    private func setRow(_ log: SetLog) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.absSkill?.name ?? "—").bold()
                Spacer()
                Text("R\(log.roundIndex + 1)·\(log.orderInRound + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Text("reps \(log.reps) · ROM \(log.rom)% · RPT \(log.rpt) · RPE \(log.rpe) · RPD \(log.rpd) ·")
                    .foregroundStyle(.secondary)
                Text(log.decisionValue.label)
                    .foregroundStyle(log.decisionValue.color)
                    .bold()
            }
            .font(.caption)
            if let notes = log.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(.tertiarySystemBackground)))
            }
            if log.hrAvg > 0 {
                Text("HR avg \(log.hrAvg) (min \(log.hrMin), max \(log.hrMax))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
