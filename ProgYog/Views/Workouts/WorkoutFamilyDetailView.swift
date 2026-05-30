//
//  WorkoutFamilyDetailView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutFamilyDetailView: View {
    @ObservedObject var session: Session
    let family: CDSkillFamily

    @EnvironmentObject private var services: AppServices
    @State private var sheet: Sheet?

    private enum Sheet: Identifiable {
        case edit(SetLog)
        case add(CDAbsSkill)

        var id: String {
            switch self {
            case .edit(let l): return "edit-\(l.objectID.uriRepresentation().absoluteString)"
            case .add(let s):  return "add-\(s.objectID.uriRepresentation().absoluteString)"
            }
        }
    }

    var body: some View {
        List {
            if !familyLogs.isEmpty {
                Section("Composite") {
                    WorkoutCompositeChart(logs: familyLogs)
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
                        CompletionChip(
                            percent: CompletionScorer.roundFamilyPercent(
                                in: session, family: family, round: group.round
                            )
                        )
                    }
                }
            }

            Section {
                Button {
                    if let skill = familyLogs.last?.absSkill ?? family.orderedAbsSkills.last {
                        sheet = .add(skill)
                    }
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(family.name)
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

    private var familyLogs: [SetLog] {
        session.orderedSetLogs.filter { $0.absSkill?.skillFamily == family }
    }

    private var roundGroups: [(round: Int16, logs: [SetLog])] {
        let dict = Dictionary(grouping: familyLogs) { $0.roundIndex }
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
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func deleteLog(_ log: SetLog) {
        let snap = SessionRecovery.snapshot(log)
        let coreData = services.coreData
        let captured = session
        services.undo.push(description: "1 set") {
            _ = SessionRecovery.restore(snap, into: coreData.moc, session: captured)
            coreData.save()
            WorkoutCalendarBridge.syncSegments(captured)
            WorkoutHealthBridge.syncSegments(captured)
        }
        services.coreData.moc.delete(log)
        services.coreData.save()
        WorkoutCalendarBridge.syncSegments(session)
        WorkoutHealthBridge.syncSegments(session)
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
        WorkoutCalendarBridge.syncSegments(session)
        WorkoutHealthBridge.syncSegments(session)
    }

    private func createLog(for skill: CDAbsSkill, entry: SetLogSheet.Entry) {
        let log = SetLog(context: services.coreData.moc)
        log.id = UUID()
        log.session = session
        log.absSkill = skill
        let existing = session.orderedSetLogs
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
        WorkoutCalendarBridge.syncSegments(session)
        WorkoutHealthBridge.syncSegments(session)
    }
}
