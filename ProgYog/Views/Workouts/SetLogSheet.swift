//
//  SetLogSheet.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SetLogSheet: View {
    let skill: CDAbsSkill
    let suggestion: ProgressionDecision
    let onSave: (_ entry: Entry) -> Void

    struct Entry {
        let reps: Int
        let rpt: Int
        let rpe: Int
        let rpd: Int
        let rptNote: String
        let rpeNote: String
        let rpdNote: String
        let decision: ProgressionDecision
    }

    @FetchRequest private var logs: FetchedResults<SetLog>

    @State private var reps: Int = 1
    @State private var rpt: Int = 7
    @State private var rpe: Int = 6
    @State private var rpd: Int = 3
    @State private var rptNote: String = ""
    @State private var rpeNote: String = ""
    @State private var rpdNote: String = ""
    @State private var decision: ProgressionDecision = .hold
    @Environment(\.dismiss) private var dismiss

    init(skill: CDAbsSkill, suggestion: ProgressionDecision, onSave: @escaping (Entry) -> Void) {
        self.skill = skill
        self.suggestion = suggestion
        self.onSave = onSave
        _logs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: true)],
            predicate: NSPredicate(format: "absSkill == %@", skill)
        )
    }

    private var lastLog: SetLog? { logs.last }

    var body: some View {
        NavigationStack {
            Form {
                Section(skill.name) {
                    Text("Level \(skill.depth)").foregroundStyle(.secondary)
                }

                if logs.count >= 2 {
                    Section("Trend") {
                        SkillTrendChart(logs: Array(logs))
                    }
                }

                Section {
                    Stepper(value: $reps, in: 0...200) {
                        HStack {
                            Text("\(reps)").monospacedDigit().font(.title3.bold())
                            if let last = lastLog {
                                Text("last \(last.reps)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: { Text("Reps") }

                metricSection(
                    title: "Technique (RPT)",
                    value: $rpt,
                    note: $rptNote,
                    placeholder: lastLog?.rptNote,
                    hint: "10 = perfect form"
                )
                metricSection(
                    title: "Exertion (RPE)",
                    value: $rpe,
                    note: $rpeNote,
                    placeholder: lastLog?.rpeNote,
                    hint: "10 = max effort"
                )
                metricSection(
                    title: "Discomfort (RPD)",
                    value: $rpd,
                    note: $rpdNote,
                    placeholder: lastLog?.rpdNote,
                    hint: "10 = worst pain"
                )

                Section {
                    Picker("Decision", selection: $decision) {
                        ForEach(ProgressionDecision.allCases, id: \.self) { d in
                            Text(d.rawValue.capitalized).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Suggested: \(suggestion.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Next Set")
                }
            }
            .navigationTitle("Log Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(Entry(
                            reps: reps,
                            rpt: rpt, rpe: rpe, rpd: rpd,
                            rptNote: rptNote, rpeNote: rpeNote, rpdNote: rpdNote,
                            decision: decision
                        ))
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                if let last = lastLog {
                    reps = Int(last.reps)
                    rpt = Int(last.rpt)
                    rpe = Int(last.rpe)
                    rpd = Int(last.rpd)
                }
                decision = suggestion
            }
        }
    }

    @ViewBuilder
    private func metricSection(title: String, value: Binding<Int>, note: Binding<String>, placeholder: String?, hint: String) -> some View {
        Section(title) {
            Stepper(value: value, in: 1...10) {
                HStack {
                    Text("\(value.wrappedValue)")
                        .monospacedDigit()
                        .font(.title3.bold())
                        .frame(width: 36, alignment: .leading)
                    Text(hint).font(.caption).foregroundStyle(.secondary)
                }
            }
            TextField(
                "Notes (optional)",
                text: note,
                prompt: Text(placeholder?.isEmpty == false ? placeholder! : "Notes (optional)"),
                axis: .vertical
            )
            .lineLimit(1...3)
        }
    }
}
