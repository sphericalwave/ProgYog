//
//  WorkoutSummaryView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutSummaryView: View {
    let session: Session

    private var setLogs: [SetLog] { session.orderedSetLogs }

    var body: some View {
        List {
            Section("Session") {
                LabeledContent("Workout", value: session.workoutCode)
                LabeledContent("Started", value: session.startedAt.formatted(date: .abbreviated, time: .shortened))
                if let end = session.endedAt {
                    LabeledContent("Ended", value: end.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("Sets", value: "\(setLogs.count)")
            }

            if !setLogs.isEmpty {
                Section("Composite") {
                    WorkoutCompositeChart(families: WorkoutCompositeChart.averages(from: setLogs))
                }
            }

            Section("Sets") {
                ForEach(setLogs, id: \.id) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.absSkill?.name ?? "—").bold()
                            Spacer()
                            Text("R\(log.roundIndex + 1)·\(log.orderInRound + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("RPT \(log.rpt) · RPE \(log.rpe) · RPD \(log.rpd) · reps \(log.reps) · \(log.decision)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if log.hrAvg > 0 {
                            Text("HR avg \(log.hrAvg) (min \(log.hrMin), max \(log.hrMax))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            HRCurveChart(samples: log.orderedHRSamples)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Summary")
    }
}
