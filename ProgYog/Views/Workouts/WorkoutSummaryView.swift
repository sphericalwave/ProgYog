//
//  WorkoutSummaryView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutSummaryView: View {
    let session: Session
    @EnvironmentObject private var services: AppServices
    @State private var notesDraft: String = ""

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

            Section("Session Notes") {
                TextField("Notes (optional)", text: $notesDraft, axis: .vertical)
                    .lineLimit(2...6)
                    .onChange(of: notesDraft) { _, new in
                        session.notes = new.isEmpty ? nil : new
                        services.coreData.save()
                    }
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
                            HRCurveChart(samples: log.orderedHRSamples)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Summary")
        .onAppear { notesDraft = session.notes ?? "" }
    }
}
