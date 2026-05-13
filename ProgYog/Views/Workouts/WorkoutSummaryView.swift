//
//  WorkoutSummaryView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct WorkoutSummaryView: View {
    let session: Session
    @EnvironmentObject private var services: AppServices
    @State private var notesDraft: String = ""
    @State private var sheet: Sheet?
    @State private var savedFlash: Bool = false

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

    private var setLogs: [SetLog] { session.orderedSetLogs }

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
                Section("Composite") {
                    WorkoutCompositeChart(families: WorkoutCompositeChart.averages(from: setLogs))
                }
            }

            Section {
                ForEach(setLogs, id: \.objectID) { log in
                    Button {
                        sheet = .edit(log)
                    } label: {
                        setRow(log)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            services.coreData.moc.delete(log)
                            services.coreData.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                Button {
                    sheet = .picker
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Sets")
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
                    suggestion: .hold,
                    currentSession: session
                ) { entry in
                    createLog(for: skill, entry: entry)
                }
            }
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
        .contentShape(Rectangle())
    }

    private func apply(_ entry: SetLogSheet.Entry, to log: SetLog) {
        log.reps = Int16(entry.reps)
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
