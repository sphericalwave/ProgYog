//
//  WorkoutSummaryView.swift
//  ProgYog
//

import SwiftUI
import SwKeyboard
import WorkoutSyncKit
import WorkoutSessionKit
import CoreData

struct WorkoutSummaryView: View {
    @ObservedObject var session: Session
    @EnvironmentObject private var services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var notesDraft: String = ""
    @State private var savedFlash: Bool = false
    @State private var resumePresented = false
    @State private var scheduleNextPresented = false
    #if canImport(EventKit)
    @AppStorage(WorkoutCalendar.enabledKey) private var calendarEnabled = false
    #endif

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
                InProgressSessionControls(
                    onResume: { resumePresented = true },
                    onComplete: completeSession,
                    onDiscard: discardSession,
                    completeMessage: "Marks this session as finished with the rounds already logged.",
                    discardMessage: "This will permanently remove the in-progress session and all logged sets. Shake to undo."
                )
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

            #if canImport(EventKit)
            calendarBannerSection
            #endif

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
            ToolbarItem(placement: .automatic) {
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
            .doneKeyboardToolbar()
        }
        .sheet(isPresented: $scheduleNextPresented) {
            ScheduleNextWorkoutSheet(
                workoutName: WorkoutLabel.display(for: session),
                workoutCode: session.workoutCode
            )
        }
    }

    // MARK: - In-progress actions

    private func completeSession() {
        session.endedAt = Date()
        services.coreData.save()
        WorkoutCalendarBridge.syncSegments(session)
        #if canImport(HealthKit)
        WorkoutHealthBridge.syncSegments(session)
        #endif
        scheduleNextPresented = true
    }

    private func discardSession() {
        // Snapshot while the object is still alive, then pop the view BEFORE
        // deleting. Deleting a session that backs a live NavigationLink
        // destination (+ our session==%@ FetchRequest) traps in
        // _PFFaultHandler; dismissing first tears this view down so nothing
        // references the object when it dies.
        let snap = SessionRecovery.snapshot(session)
        let session = self.session
        let coreData = services.coreData
        let undo = services.undo
        dismiss()
        DispatchQueue.main.async {
            undo.push(description: "in-progress session") {
                let restored = SessionRecovery.restore(snap, into: coreData.moc)
                coreData.save()
                WorkoutCalendarBridge.syncSegments(restored)
                #if canImport(HealthKit)
                WorkoutHealthBridge.syncSegments(restored)
                #endif
            }
            WorkoutCalendarBridge.removeAll(for: session)
            #if canImport(HealthKit)
            WorkoutHealthBridge.removeAll(for: session)
            #endif
            coreData.moc.delete(session)
            coreData.save()
        }
    }

    // MARK: - Session summary row

    @ViewBuilder
    private var sessionSummaryRow: some View {
        let scored = scoredFamilies
        let worst = scored.min { a, b in a.pct != b.pct ? a.pct < b.pct : a.family.order < b.family.order }?.family
        let best = scored.max { a, b in a.pct != b.pct ? a.pct < b.pct : a.family.order > b.family.order }?.family
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
                CompletionChip(percent: CompletionScorer.sessionPercent(session))
                if let worst {
                    SkillThumbnail(assetName: lastFamilyLog(worst)?.absSkill?.posterAssetName, size: 40)
                }
                if let best, best != worst {
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

    // MARK: - Completion section helpers

    /// Families logged in this session, ordered by `CDSkillFamily.order`.
    private var completionFamilies: [CDSkillFamily] {
        let families = Set(setLogs.compactMap { $0.absSkill?.skillFamily })
        return families.sorted { $0.order < $1.order }
    }

    private func lastFamilyLog(_ family: CDSkillFamily) -> SetLog? {
        setLogs.filter { $0.absSkill?.skillFamily == family }.last
    }

    // MARK: - Calendar banner

    #if canImport(EventKit)
    @ViewBuilder
    private var calendarBannerSection: some View {
        if calendarEnabled && WorkoutCalendar.isAuthorized {
            let segments = WorkoutSegmenter.segments(of: session)
            if !segments.isEmpty {
                Section {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                        Button { openCalendar(at: seg.startedAt) } label: {
                            calendarChip(for: seg)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
            }
        }
    }

    private func calendarChip(for seg: WorkoutSegment) -> some View {
        let accentColor = Color(hex: WorkoutCalendar.colorHex) ?? .orange
        return HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.headline)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(WorkoutLabel.display(for: session))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(seg.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(accentColor))
    }

    private func openCalendar(at date: Date) {
        let interval = Int(date.timeIntervalSinceReferenceDate)
        if let url = URL(string: "calshow:\(interval)") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #else
            NSWorkspace.shared.open(url)
            #endif
        }
    }
    #endif

    // MARK: - Completion rows

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
