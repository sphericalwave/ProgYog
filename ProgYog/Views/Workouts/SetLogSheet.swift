//
//  SetLogSheet.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SetLogSheet: View {
    let skill: CDAbsSkill
    let suggestion: ProgressionDecision
    let editing: SetLog?
    let currentSession: Session?
    let liveHRStats: (min: Int, max: Int, avg: Int)?
    let onSave: (_ entry: Entry) -> Void
    let onCancel: (() -> Void)?
    
    struct Entry {
        let reps: Int
        let rom: Int
        let rpt: Int
        let rpe: Int
        let rpd: Int
        let notes: String
        let decision: ProgressionDecision
    }

    @FetchRequest private var logs: FetchedResults<SetLog>

    @State private var reps: Int = 1
    @State private var rom: Int = 100
    @State private var rpt: Int = 7
    @State private var rpe: Int = 6
    @State private var rpd: Int = 3
    @State private var notes: String = ""
    @State private var decision: ProgressionDecision = .`repeat`
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(HRSettings.ageKey) private var hrAge = 30
    @AppStorage(HRSettings.overrideKey) private var hrMaxOverride = 0

    init(
        skill: CDAbsSkill,
        suggestion: ProgressionDecision,
        editing: SetLog? = nil,
        currentSession: Session? = nil,
        liveHRStats: (min: Int, max: Int, avg: Int)? = nil,
        onSave: @escaping (Entry) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.skill = skill
        self.suggestion = suggestion
        self.editing = editing
        self.currentSession = currentSession ?? editing?.session
        self.liveHRStats = liveHRStats
        self.onSave = onSave
        self.onCancel = onCancel
        _logs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: true)],
            predicate: NSPredicate(format: "absSkill == %@", skill)
        )
    }
    
    private var lastLog: SetLog? { logs.last }
    
    var body: some View {
        NavigationStack {
            Form {

                if let hr = resolvedHRStats {
                    Section("Heart rate") {
                        hrStatRow("Min", hr.min)
                        hrStatRow("Avg", hr.avg)
                        hrStatRow("Max", hr.max)
                    }
                }

                Section {
                    
                    metricRow(label: "Reps", value: $reps, range: 0...200)
                    metricRow(label: "ROM",  value: $rom,  range: 0...100, step: 10, suffix: "%")
                    metricRow(label: "Technique", value: $rpt, range: 1...10)
                    metricRow(label: "Exertion",  value: $rpe, range: 1...10)
                    metricRow(label: "Discomfort", value: $rpd, range: 1...10)
                    
                    HStack {
                        TextField(
                            "Notes (optional)",
                            text: $notes,
                            prompt: Text(notesPlaceholder),
                            axis: .vertical
                        )
                        .lineLimit(2...6)
                        
                        if let last = lastLog?.notes, !last.isEmpty {
                            Button(action: { notes = last }) {
                                Image(systemName: "arrow.uturn.left")
                                    .imageScale(.large)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Picker("Decision", selection: $decision) {
                        ForEach(ProgressionDecision.allCases, id: \.self) { d in
                            Text(d.rawValue.capitalized).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                } header : {
                    HStack {
                        Text(skill.name)
                        Spacer()
                        Text("Level \(skill.depth)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if logs.count >= 2 {
                    Section("Trend") {
                        SkillTrendChart(logs: Array(logs), highlightSession: currentSession)
                    }
                }
            }
            .navigationTitle(editing == nil ? "Log Set" : "Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(Entry(
                            reps: reps, rom: rom,
                            rpt: rpt, rpe: rpe, rpd: rpd,
                            notes: notes, decision: decision
                        ))
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                if let edit = editing {
                    reps = Int(edit.reps)
                    rom = Int(edit.rom)
                    rpt = Int(edit.rpt)
                    rpe = Int(edit.rpe)
                    rpd = Int(edit.rpd)
                    notes = edit.notes ?? ""
                    decision = edit.decisionValue
                } else {
                    if let last = lastLog {
                        reps = Int(last.reps)
                        rom = Int(last.rom)
                        rpt = Int(last.rpt)
                        rpe = Int(last.rpe)
                        rpd = Int(last.rpd)
                    }
                    decision = suggestion
                }
            }
        }
    }
    
    /// Most recent set (for this skill) that actually has a comment.
    private var lastNote: String? {
        logs.reversed().lazy
            .compactMap(\.notes)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var notesPlaceholder: String {
        lastNote ?? "Notes (optional)"
    }
    
    /// HR stats for this set: a saved log's stored values when editing,
    /// otherwise the live stats from the just-finished set. nil → no HR row.
    private var resolvedHRStats: (min: Int, max: Int, avg: Int)? {
        if let e = editing, e.hrAvg > 0 {
            return (Int(e.hrMin), Int(e.hrMax), Int(e.hrAvg))
        }
        return liveHRStats
    }

    @ViewBuilder
    private func hrStatRow(_ label: String, _ bpm: Int) -> some View {
        let hrMax = HRSettings.effectiveMax(age: hrAge, manualOverride: hrMaxOverride)
        HStack(spacing: 12) {
            Text(label).font(.callout)
            Spacer()
            Text("\(bpm) bpm")
                .monospacedDigit()
                .font(.title3.bold())
            Text("\(hrMax > 0 ? bpm * 100 / hrMax : 0)%")
                .monospacedDigit()
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func metricRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        suffix: String = ""
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.callout)
                Spacer()
                Text("\(value.wrappedValue)\(suffix)")
                    .monospacedDigit()
                    .font(.title3.bold())
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
    }
}

#if DEBUG
private struct SetLogSheetPreviewHost: View {
    @State private var presented = true
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .sheet(isPresented: $presented) {
                SetLogSheet(
                    skill: PreviewSupport.sampleSkill,
                    suggestion: .progress,
                    currentSession: PreviewSupport.sampleSession,
                    onSave: { _ in }
                )
                .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
            }
    }
}

#Preview("Modal") {
    SetLogSheetPreviewHost()
}

#Preview("Inline") {
    SetLogSheet(
        skill: PreviewSupport.sampleSkill,
        suggestion: .progress,
        currentSession: PreviewSupport.sampleSession,
        onSave: { _ in }
    )
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
