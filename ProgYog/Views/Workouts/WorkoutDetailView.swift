//
//  WorkoutDetailView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    let workoutCode: String

    @EnvironmentObject private var services: AppServices
    @State private var sessionPresented = false
    @State private var resuming: Session?
    @State private var inProgress: Session?
    @State private var discardAlert = false

    @FetchRequest private var families: FetchedResults<CDSkillFamily>
    @FetchRequest private var setLogs: FetchedResults<SetLog>
    @FetchRequest private var sessions: FetchedResults<Session>

    init(workoutCode: String) {
        self.workoutCode = workoutCode
        _families = FetchRequest<CDSkillFamily>(
            sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)],
            predicate: NSPredicate(format: "series == %@", workoutCode)
        )
        _setLogs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: false)],
            predicate: NSPredicate(format: "absSkill.skillFamily.series == %@", workoutCode)
        )
        _sessions = FetchRequest<Session>(
            sortDescriptors: [NSSortDescriptor(key: "startedAt", ascending: false)],
            predicate: NSPredicate(format: "workoutCode == %@", workoutCode)
        )
    }

    var body: some View {
        List {
            if let session = inProgress {
                Section("In Progress") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Started \(session.startedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(session.orderedSetLogs.count) sets logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        resuming = session
                        sessionPresented = true
                    } label: {
                        Label("Resume", systemImage: "play.circle.fill")
                    }
                    Button(role: .destructive) {
                        discardAlert = true
                    } label: {
                        Label("Discard", systemImage: "trash")
                    }
                }
            }

            Section("Skill Families") {
                ForEach(families, id: \.self) { family in
                    NavigationLink {
                        SkillFamilyDetailView(family: family)
                    } label: {
                        HStack {
                            Text("\(family.order).")
                                .foregroundStyle(.secondary)
                            Text(family.name)
                            Spacer()
                            stats(for: family)
                            CompletionChip(
                                percent: CompletionScorer.allTimeBestFamilyPercent(family),
                                caption: "best"
                            )
                        }
                    }
                }
            }

            if !sessions.isEmpty {
                Section("Session History") {
                    ForEach(sessions, id: \.objectID) { session in
                        NavigationLink {
                            WorkoutSummaryView(session: session)
                        } label: {
                            sessionRow(session)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                _ = services.coreData.duplicateSession(session)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(WorkoutLabel.display(forCode: workoutCode))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(inProgress == nil ? "Start" : "New") {
                    resuming = nil
                    sessionPresented = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear(perform: refreshInProgress)
        .fullScreenCover(isPresented: $sessionPresented, onDismiss: refreshInProgress) {
            NavigationStack {
                WorkoutSessionView(workoutCode: workoutCode, services: services, resuming: resuming)
            }
            .keyboardDoneToolbar()
        }
        .alert("Discard session?", isPresented: $discardAlert) {
            Button("Discard", role: .destructive) {
                guard let session = inProgress else { return }
                let snap = SessionRecovery.snapshot(session)
                let coreData = services.coreData
                services.undo.push(description: "in-progress session") {
                    let restored = SessionRecovery.restore(snap, into: coreData.moc)
                    coreData.save()
                    if restored.endedAt != nil {
                        WorkoutCalendarBridge.syncCompleted(restored)
                    }
                }
                inProgress = nil
                WorkoutCalendarBridge.remove(session)
                services.coreData.moc.delete(session)
                services.coreData.save()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the in-progress session and all logged sets. Shake to undo.")
        }
    }

    private func refreshInProgress() {
        inProgress = WorkoutSessionViewModel.inProgressSession(for: workoutCode, moc: services.coreData.moc)
    }

    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.bold())
                Text("\(session.orderedSetLogs.count) sets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            CompletionChip(percent: CompletionScorer.sessionPercent(session))
        }
    }

    @ViewBuilder
    private func stats(for family: CDSkillFamily) -> some View {
        let logs = setLogs.filter { $0.absSkill?.skillFamily == family }
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(logs.count) \(logs.count == 1 ? "set" : "sets")")
                .font(.caption.bold())
                .monospacedDigit()
            if let last = logs.first?.loggedAt {
                Text(last.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("never")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkoutDetailView(workoutCode: "A")
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
