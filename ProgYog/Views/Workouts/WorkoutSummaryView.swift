//
//  WorkoutSummaryView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct WorkoutSummaryView: View {
    @ObservedObject var session: Session
    @EnvironmentObject private var services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var notesDraft: String = ""
    @State private var savedFlash: Bool = false
    @State private var resumePresented = false
    @State private var discardAlert = false

    let onDone: (() -> Void)?

    @FetchRequest private var setLogs: FetchedResults<SetLog>

    init(session: Session, onDone: (() -> Void)? = nil) {
        self.session = session
        self.onDone = onDone
        _setLogs = FetchRequest<SetLog>(
            sortDescriptors: [
                NSSortDescriptor(key: "roundIndex", ascending: true),
                NSSortDescriptor(key: "orderInRound", ascending: true),
                NSSortDescriptor(key: "loggedAt", ascending: true),
            ],
            predicate: NSPredicate(format: "session == %@", session)
        )
    }

    /// Session may be deleted (Discard) while this view is still in the
    /// nav stack mid-dismissal. Accessing `session.startedAt` etc. on a
    /// deleted/orphaned NSManagedObject traps in `_PFFaultHandler`, so
    /// short-circuit the body to a placeholder until SwiftUI tears us down.
    private var sessionAlive: Bool {
        !session.isDeleted && session.managedObjectContext != nil
    }

    var body: some View {
        if !sessionAlive {
            Color.clear
        } else {
            sessionBody
        }
    }

    @ViewBuilder
    private var sessionBody: some View {
        List {
            if session.endedAt == nil {
                Section("In Progress") {
                    Button {
                        resumePresented = true
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

            Section {
                NavigationLink {
                    SessionInfoDetailView(session: session)
                } label: {
                    sessionSummaryRow
                }
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
                Section {
                    WorkoutFamilyCompletionChart(points: WorkoutFamilyCompletionChart.points(for: session))
                    
                    ForEach(completionFamilies, id: \.objectID) { family in
                        NavigationLink {
                            WorkoutFamilyDetailView(session: session, family: family)
                        } label: {
                            completionRow(family)
                        }
                    }
                } header: {
                    HStack {
                        Text("Session %").bold()
                        Spacer()
                        CompletionChip(percent: CompletionScorer.sessionPercent(session))
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Summary")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let onDone {
                    Button("Done") {
                        services.coreData.save()
                        onDone()
                    }
                    .bold()
                } else {
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
        .fullScreenCover(isPresented: $resumePresented) {
            NavigationStack {
                WorkoutSessionView(
                    workoutCode: session.workoutCode,
                    services: services,
                    resuming: session
                )
            }
            .keyboardDoneToolbar()
        }
        .alert("Discard session?", isPresented: $discardAlert) {
            Button("Discard", role: .destructive) {
                let snap = SessionRecovery.snapshot(session)
                let coreData = services.coreData
                services.undo.push(description: "in-progress session") {
                    let restored = SessionRecovery.restore(snap, into: coreData.moc)
                    coreData.save()
                    WorkoutCalendarBridge.syncSegments(restored)
                }
                WorkoutCalendarBridge.removeAll(for: session)
                services.coreData.moc.delete(session)
                services.coreData.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the in-progress session and all logged sets. Shake to undo.")
        }
    }

    // MARK: - Session summary row

    @ViewBuilder
    private var sessionSummaryRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(WorkoutLabel.display(for: session))
                    .font(.body).bold()
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(setLogs.count) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                if let worst = lowestScoredFamily {
                    SkillThumbnail(assetName: lastFamilyLog(worst)?.absSkill?.posterAssetName, size: 40)
                }
                if let best = highestScoredFamily, best != lowestScoredFamily {
                    SkillThumbnail(assetName: lastFamilyLog(best)?.absSkill?.posterAssetName, size: 40)
                }
            }
        }
    }

    private var scoredFamilies: [(family: CDSkillFamily, pct: Double)] {
        completionFamilies.compactMap { family in
            guard let pct = CompletionScorer.familyPercent(in: session, family: family) else { return nil }
            return (family, pct)
        }
    }

    private var lowestScoredFamily: CDSkillFamily? {
        scoredFamilies.min { a, b in
            a.pct != b.pct ? a.pct < b.pct : a.family.order < b.family.order
        }?.family
    }

    private var highestScoredFamily: CDSkillFamily? {
        scoredFamilies.max { a, b in
            a.pct != b.pct ? a.pct < b.pct : a.family.order > b.family.order
        }?.family
    }

    // MARK: - Completion section helpers

    /// Families logged in this session, ordered by `CDSkillFamily.order`.
    private var completionFamilies: [CDSkillFamily] {
        let families = Set(setLogs.compactMap { $0.absSkill?.skillFamily })
        return families.sorted { $0.order < $1.order }
    }

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
