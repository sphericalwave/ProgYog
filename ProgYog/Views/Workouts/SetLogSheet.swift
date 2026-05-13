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
    let onSave: (_ entry: Entry) -> Void
    
    struct Entry {
        let reps: Int
        let rpt: Int
        let rpe: Int
        let rpd: Int
        let notes: String
        let decision: ProgressionDecision
    }
    
    @FetchRequest private var logs: FetchedResults<SetLog>
    
    @State private var reps: Int = 1
    @State private var rpt: Int = 7
    @State private var rpe: Int = 6
    @State private var rpd: Int = 3
    @State private var notes: String = ""
    @State private var decision: ProgressionDecision = .hold
    @Environment(\.dismiss) private var dismiss
    
    init(
        skill: CDAbsSkill,
        suggestion: ProgressionDecision,
        editing: SetLog? = nil,
        currentSession: Session? = nil,
        onSave: @escaping (Entry) -> Void
    ) {
        self.skill = skill
        self.suggestion = suggestion
        self.editing = editing
        self.currentSession = currentSession ?? editing?.session
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
                
                Section {
                    metricRow(label: "Reps", value: $reps, range: 0...200)
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
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button("Save") {
                        onSave(Entry(
                            reps: reps, rpt: rpt, rpe: rpe, rpd: rpd,
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
                    rpt = Int(edit.rpt)
                    rpe = Int(edit.rpe)
                    rpd = Int(edit.rpd)
                    notes = edit.notes ?? ""
                    decision = edit.decisionValue
                } else {
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
    }
    
    private var notesPlaceholder: String {
        let last = lastLog?.notes ?? ""
        return last.isEmpty ? "Notes (optional)" : last
    }
    
    @ViewBuilder
    private func metricRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.callout)
                Spacer()
                Text("\(value.wrappedValue)")
                    .monospacedDigit()
                    .font(.title3.bold())
                    .frame(minWidth: 36, alignment: .trailing)
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
