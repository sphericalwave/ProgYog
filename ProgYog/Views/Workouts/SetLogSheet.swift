//
//  SetLogSheet.swift
//  ProgYog
//

import SwiftUI

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

    @State private var reps: Int = 1
    @State private var rpt: Int = 7
    @State private var rpe: Int = 6
    @State private var rpd: Int = 3
    @State private var rptNote: String = ""
    @State private var rpeNote: String = ""
    @State private var rpdNote: String = ""
    @State private var decision: ProgressionDecision = .hold
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(skill.name) {
                    Text("Level \(skill.depth)").foregroundStyle(.secondary)
                }

                Section("Reps") {
                    Stepper(value: $reps, in: 0...200) {
                        Text("\(reps)").monospacedDigit()
                    }
                }

                metricSection(
                    title: "Technique (RPT)",
                    value: $rpt,
                    note: $rptNote,
                    hint: "10 = perfect form"
                )
                metricSection(
                    title: "Exertion (RPE)",
                    value: $rpe,
                    note: $rpeNote,
                    hint: "10 = max effort"
                )
                metricSection(
                    title: "Discomfort (RPD)",
                    value: $rpd,
                    note: $rpdNote,
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
            .onAppear { decision = suggestion }
        }
    }

    @ViewBuilder
    private func metricSection(title: String, value: Binding<Int>, note: Binding<String>, hint: String) -> some View {
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
            TextField("Notes (optional)", text: note, axis: .vertical)
                .lineLimit(1...3)
        }
    }
}
