//
//  WorkoutSummaryView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct WorkoutSummaryView: View {
    @ObservedObject var session: Session
    @EnvironmentObject private var services: AppServices
    @State private var notesDraft: String = ""
    @State private var sheet: Sheet?
    @State private var savedFlash: Bool = false

    @FetchRequest private var setLogs: FetchedResults<SetLog>

    init(session: Session) {
        self.session = session
        _setLogs = FetchRequest<SetLog>(
            sortDescriptors: [
                NSSortDescriptor(key: "roundIndex", ascending: true),
                NSSortDescriptor(key: "orderInRound", ascending: true),
                NSSortDescriptor(key: "loggedAt", ascending: true),
            ],
            predicate: NSPredicate(format: "session == %@", session)
        )
    }

    private enum Sheet: Identifiable {
        case edit(SetLog)
        case picker
        case add(CDAbsSkill)

        var id: String {
            switch self {
            case .edit(let l): return "edit-\(l.objectID.uriRepresentation().absoluteString)"
            case .picker:      return "picker"
            case .add(let s):  return "add-\(s.objectID.uriRepresentation().absoluteString)"
            }
        }
    }

    var body: some View {
        List {
            if let err = services.coreData.lastSaveError {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Couldn't save", systemImage: "exclamationmark.octagon.fill")
                            .foregroundStyle(.red)
                            .font(.headline)
                        Text(err).font(.caption)
                        Button("Retry") { services.coreData.save() }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.red.opacity(0.08))
            }

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
                Section("Completion") {
                    HStack {
                        Text("Session").bold()
                        Spacer()
                        CompletionChip(percent: CompletionScorer.sessionPercent(session))
                    }
                    ForEach(completionFamilies, id: \.objectID) { family in
                        completionRow(family)
                    }
                }

                Section("Composite") {
                    WorkoutCompositeChart(families: WorkoutCompositeChart.averages(from: Array(setLogs)))
                }
            }

            ForEach(roundGroups, id: \.round) { group in
                Section {
                    ForEach(group.logs, id: \.objectID) { log in
                        Button {
                            sheet = .edit(log)
                        } label: {
                            setRow(log)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteLog(log)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Round \(group.round + 1)")
                        Spacer()
                        Button {
                            duplicateRound(group)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                                .labelStyle(.iconOnly)
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section {
                Button {
                    sheet = .picker
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                }
            } footer: {
                Text("Changes save automatically. Tap Save to confirm.")
                    .font(.caption2)
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Summary")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 6) {
                    if savedFlash {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                    Button("Save") {
                        services.coreData.save()
                        if services.coreData.lastSaveError == nil {
                            withAnimation { savedFlash = true }
                            Task {
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                withAnimation { savedFlash = false }
                            }
                        }
                    }
                    .bold()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let saved = services.coreData.lastSavedAt {
                Text("Saved \(saved.formatted(date: .omitted, time: .standard))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .onAppear { notesDraft = session.notes ?? "" }
        .sheet(item: $sheet) { state in
            switch state {
            case .edit(let log):
                if let skill = log.absSkill {
                    SetLogSheet(
                        skill: skill,
                        suggestion: log.decisionValue,
                        editing: log,
                        currentSession: session
                    ) { entry in
                        apply(entry, to: log)
                    }
                }
            case .picker:
                SkillPickerSheet(workoutCode: session.workoutCode) { skill in
                    sheet = .add(skill)
                }
            case .add(let skill):
                SetLogSheet(
                    skill: skill,
                    suggestion: .`repeat`,
                    currentSession: session
                ) { entry in
                    createLog(for: skill, entry: entry)
                }
            }
        }
    }

    private func deleteLog(_ log: SetLog) {
        guard let session = log.session else {
            services.coreData.moc.delete(log)
            services.coreData.save()
            return
        }
        let snap = SessionRecovery.snapshot(log)
        let coreData = services.coreData
        services.undo.push(description: "1 set") {
            _ = SessionRecovery.restore(snap, into: coreData.moc, session: session)
            coreData.save()
        }
        services.coreData.moc.delete(log)
        services.coreData.save()
    }

    private func duplicateRound(_ group: (round: Int16, logs: [SetLog])) {
        let nextRound = (roundGroups.map { $0.round }.max() ?? -1) + 1
        for src in group.logs {
            let dup = SetLog(context: services.coreData.moc)
            dup.id = UUID()
            dup.session = session
            dup.absSkill = src.absSkill
            dup.roundIndex = nextRound
            dup.orderInRound = src.orderInRound
            dup.reps = src.reps
            dup.rom = src.rom
            dup.rpt = src.rpt
            dup.rpe = src.rpe
            dup.rpd = src.rpd
            dup.notes = src.notes
            dup.durationSec = src.durationSec
            dup.decision = src.decision
            dup.loggedAt = Date()
        }
        services.coreData.save()
    }

    /// Families logged in this session, ordered by `CDSkillFamily.order`.
    private var completionFamilies: [CDSkillFamily] {
        let families = Set(setLogs.compactMap { $0.absSkill?.skillFamily })
        return families.sorted { $0.order < $1.order }
    }

    /// Last set logged for `family` in this session (by round / order).
    private func lastFamilyLog(_ family: CDSkillFamily) -> SetLog? {
        setLogs.filter { $0.absSkill?.skillFamily == family }.last
    }

    @ViewBuilder
    private func completionRow(_ family: CDSkillFamily) -> some View {
        let pct = CompletionScorer.familyPercent(in: session, family: family)
        HStack {
            Text(family.name)
            Spacer()
            if let last = lastFamilyLog(family), let depth = last.absSkill?.depth {
                Text("\(depth)/\(family.maxDepth)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            CompletionChip(percent: pct)
        }
    }

    private var roundGroups: [(round: Int16, logs: [SetLog])] {
        let dict = Dictionary(grouping: Array(setLogs)) { $0.roundIndex }
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
                HRCurveChart(samples: log.orderedHRSamples)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func apply(_ entry: SetLogSheet.Entry, to log: SetLog) {
        log.reps = Int16(entry.reps)
        log.rom = Int16(entry.rom)
        log.rpt = Int16(entry.rpt)
        log.rpe = Int16(entry.rpe)
        log.rpd = Int16(entry.rpd)
        log.notes = entry.notes.isEmpty ? nil : entry.notes
        log.decision = entry.decision.rawValue
        services.coreData.save()
    }

    private func createLog(for skill: CDAbsSkill, entry: SetLogSheet.Entry) {
        let log = SetLog(context: services.coreData.moc)
        log.id = UUID()
        log.session = session
        log.absSkill = skill
        let existing = setLogs
        let lastRound = existing.last?.roundIndex ?? 0
        let inRound = existing.filter { $0.roundIndex == lastRound }.count
        log.roundIndex = Int16(lastRound)
        log.orderInRound = Int16(inRound)
        log.reps = Int16(entry.reps)
        log.rom = Int16(entry.rom)
        log.rpt = Int16(entry.rpt)
        log.rpe = Int16(entry.rpe)
        log.rpd = Int16(entry.rpd)
        log.notes = entry.notes.isEmpty ? nil : entry.notes
        log.durationSec = 60
        log.decision = entry.decision.rawValue
        log.loggedAt = Date()
        services.coreData.save()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkoutSummaryView(session: PreviewSupport.sampleSession)
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
