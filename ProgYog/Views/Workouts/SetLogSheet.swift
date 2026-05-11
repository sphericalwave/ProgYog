//
//  SetLogSheet.swift
//  ProgYog
//

import SwiftUI

struct SetLogSheet: View {
    let skill: CDAbsSkill
    let suggestion: ProgressionDecision
    let onSave: (_ reps: Int, _ rpt: Int, _ rpe: Int, _ rpd: Int, _ decision: ProgressionDecision) -> Void

    @State private var reps: Int = 1
    @State private var rpt: Int = 7
    @State private var rpe: Int = 6
    @State private var rpd: Int = 3
    @State private var decision: ProgressionDecision = .hold
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(skill.name) {
                    Text("Depth \(skill.depth)").foregroundStyle(.secondary)
                }

                Section("Reps") {
                    Stepper(value: $reps, in: 0...200) {
                        Text("\(reps)").monospacedDigit()
                    }
                }

                ratingSection(title: "Technique (RPT)", value: $rpt, hint: "10 = perfect form")
                ratingSection(title: "Exertion (RPE)", value: $rpe, hint: "10 = max effort")
                ratingSection(title: "Discomfort (RPD)", value: $rpd, hint: "10 = worst pain")

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
                        onSave(reps, rpt, rpe, rpd, decision)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear { decision = suggestion }
        }
    }

    @ViewBuilder
    private func ratingSection(title: String, value: Binding<Int>, hint: String) -> some View {
        Section {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)")
                    .monospacedDigit()
                    .font(.title3.bold())
                    .frame(width: 36)
            }
            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0.rounded()) }
            ), in: 1...10, step: 1)
            Text(hint).font(.caption).foregroundStyle(.secondary)
        }
    }
}
