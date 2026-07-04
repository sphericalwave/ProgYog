//
//  SetLogSheet.swift
//  ProgYog
//

import SwiftUI
import SwKeyboard
import SetLogKit
import CoreData

struct SetLogSheet: View {
    let skill: CDAbsSkill
    let suggestion: ProgressionDecision
    let editing: SetLog?
    let currentSession: Session?
    let liveHRStats: (min: Int, max: Int, avg: Int)?
    let isFinalRound: Bool
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
        let isometric: Bool
        let sliceCount: Int
    }

    @FetchRequest private var logs: FetchedResults<SetLog>

    @State private var reps: Int = 1
    @State private var rom: Int = 100
    @State private var rpt: Int = 7
    @State private var rpe: Int = 6
    @State private var rpd: Int = 3
    @State private var notes: String = ""
    @State private var decision: ProgressionDecision = .`repeat`
    @State private var isometric: Bool = false
    @State private var sliceCount: Int = 0
    @State private var showRepsInfo = false
    @State private var showSlicesInfo = false
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(HRSettings.ageKey) private var hrAge = 30
    @AppStorage(HRSettings.overrideKey) private var hrMaxOverride = 0
    @AppStorage(CompletionSettings.romMinKey) private var romMin: Int = Int(CompletionSettings.defaultRomMin)

    init(
        skill: CDAbsSkill,
        suggestion: ProgressionDecision,
        editing: SetLog? = nil,
        currentSession: Session? = nil,
        liveHRStats: (min: Int, max: Int, avg: Int)? = nil,
        isFinalRound: Bool = false,
        initialIsometric: Bool = false,
        onSave: @escaping (Entry) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.skill = skill
        self.suggestion = suggestion
        self.editing = editing
        self.currentSession = currentSession ?? editing?.session
        self.liveHRStats = liveHRStats
        self.isFinalRound = isFinalRound
        self._isometric = State(initialValue: initialIsometric)
        self.onSave = onSave
        self.onCancel = onCancel
        _logs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: true)],
            predicate: NSPredicate(format: "absSkill == %@", skill)
        )
    }
    
    private var lastLog: SetLog? { logs.last }

    /// Set score: clamp(rom / romTarget, 0–100%). Depth-independent.
    private var setScore: Double? {
        let target = Double(romMin > 0 ? romMin : Int(CompletionSettings.defaultRomMin))
        return min(100, max(0, Double(rom) / target * 100))
    }

    /// Workout score: (depth × romFraction) / maxDepth × 100.
    /// 100% only at highest skill level with full ROM.
    private var workoutScore: Double? {
        guard let family = skill.skillFamily else { return nil }
        let maxDepth = Double(family.maxDepth)
        guard maxDepth > 0 else { return nil }
        let depth = Double(skill.depth)
        let target = Double(romMin > 0 ? romMin : Int(CompletionSettings.defaultRomMin))
        let romFraction = min(1.0, max(0.0, Double(rom) / target))
        let achieved = depth * romFraction
        return min(100, (achieved / maxDepth) * 100)
    }
    
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
                    NavigationLink {
                        CompletionSettingsView()
                    } label: {
                        HStack {
                            Text("Score").font(.callout)
                            Spacer()
                            VStack(spacing: 2) {
                                Text("Set").font(.caption2).foregroundStyle(.secondary)
                                CompletionChip(percent: setScore)
                            }
                            VStack(spacing: 2) {
                                Text("Workout").font(.caption2).foregroundStyle(.secondary)
                                CompletionChip(percent: workoutScore)
                            }
                        }
                    }

                    metricRow(label: "Reps", value: $reps, range: 0...200, info: "1 rep is both sides of a skill once", showInfo: $showRepsInfo)
                    metricRow(label: "ROM",  value: $rom,  range: 0...100, step: 10, suffix: "%", colorFor: { $0 >= 80 ? .green : .red })
                    HStack(spacing: 0) {
                        compactMetric(label: "Technique", value: $rpt, range: 1...10, colorFor: FalseColor.technique, describe: TEDDescription.technique)
                        Spacer()
                        compactMetric(label: "Exertion", value: $rpe, range: 1...10, colorFor: FalseColor.exertion, describe: TEDDescription.exertion)
                        Spacer()
                        compactMetric(label: "Discomfort", value: $rpd, range: 1...10, colorFor: FalseColor.discomfort, describe: TEDDescription.discomfort)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))

                    VStack(spacing: 8) {
                        HStack {
                            TextField(
                                "Notes (optional)",
                                text: $notes,
                                prompt: Text(notesPlaceholder),
                                axis: .vertical
                            )
                            .lineLimit(2...6)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )

                            Button(action: { if let last = lastNote { notes = last } }) {
                                Image(systemName: "arrow.uturn.left")
                                    .imageScale(.large)
                            }
                            .buttonStyle(.bordered)
                            .disabled(lastNote == nil)
                        }

                        Picker("Decision", selection: $decision) {
                            ForEach(ProgressionDecision.allCases, id: \.self) { d in
                                Text(d.rawValue.capitalized).tag(d)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.accentColor)
                    }

                } header : {
                    HStack(spacing: 12) {
                        SkillAnimatedPoster(skill: skill, maxHeight: 80, cornerRadius: 8)
                            .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(skill.family)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Level \(skill.depth)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .textCase(nil)
                }

                Section {
                    Toggle("Isometric", isOn: $isometric)
                        .tint(.accentColor)
                        .onChange(of: isometric) { _, on in if on { reps = 1 } }
                    metricRow(
                        label: "Slices",
                        value: $sliceCount,
                        range: 0...30,
                        suffix: sliceCount > 0 ? " · \(sliceCount * 30)s" : "",
                        info: "Each slice is a 30-second isometric hold at a distinct position within the movement range — start, quarter, mid, three-quarter, end.",
                        showInfo: $showSlicesInfo
                    )
                }

            }
            .navigationTitle(editing == nil ? "Log Set" : "Edit Set")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .doneKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        onSave(Entry(
                            reps: reps, rom: rom,
                            rpt: rpt, rpe: rpe, rpd: rpd,
                            notes: notes, decision: decision,
                            isometric: isometric, sliceCount: sliceCount
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
                    isometric = edit.isometric
                    sliceCount = Int(edit.sliceCount)
                } else {
                    if let last = lastLog {
                        reps = Int(last.reps)
                        rom = Int(last.rom)
                        rpt = Int(last.rpt)
                        rpe = Int(last.rpe)
                        rpd = Int(last.rpd)
                    }
                    decision = suggestion
                    sliceCount = Int(skill.sliceCount)
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
    private func compactMetric(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        colorFor: ((Int) -> Color)? = nil,
        describe: ((Int) -> String)? = nil
    ) -> some View {
        let valueColor = colorFor?(value.wrappedValue) ?? .primary
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(value.wrappedValue)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(valueColor)
            }
            Stepper(value: value, in: range) { EmptyView() }
                .labelsHidden()
            if let describe {
                Text(describe(value.wrappedValue))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func metricRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        suffix: String = "",
        info: String = "",
        showInfo: Binding<Bool>? = nil,
        colorFor: ((Int) -> Color)? = nil
    ) -> some View {
        let valueColor = colorFor?(value.wrappedValue) ?? .primary
        Stepper(value: value, in: range, step: step) {
            HStack(spacing: 8) {
                Text(label).font(.callout)
                if let showInfo, !info.isEmpty {
                    Button { showInfo.wrappedValue = true } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.medium)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
                    .popover(isPresented: showInfo) {
                        Text(info)
                            .font(.callout)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .frame(maxWidth: 280)
                            .fixedSize(horizontal: false, vertical: true)
                            .presentationCompactAdaptation(.popover)
                    }
                }
                Spacer()
                Text("\(value.wrappedValue)\(suffix)")
                    .monospacedDigit()
                    .font(.title3.bold())
                    .foregroundStyle(valueColor)
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
