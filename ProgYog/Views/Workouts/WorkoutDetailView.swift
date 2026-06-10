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
    @State private var inProgress: Session?

    @FetchRequest private var families: FetchedResults<CDSkillFamily>
    @FetchRequest private var setLogs: FetchedResults<SetLog>
    @FetchRequest private var sessions: FetchedResults<Session>

    @State private var sessionPts: [FamilyPercentChart.Point] = []

    init(workoutCode: String) {
        self.workoutCode = workoutCode
        let familiesReq = NSFetchRequest<CDSkillFamily>(entityName: "CDSkillFamily")
        familiesReq.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        familiesReq.predicate = NSPredicate(format: "series == %@", workoutCode)
        familiesReq.relationshipKeyPathsForPrefetching = ["absSkills"]
        _families = FetchRequest(fetchRequest: familiesReq)
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
            if !sessionPts.isEmpty {
                Section("History") {
                    FamilyPercentChart(points: sessionPts)
                        .padding(.vertical, 4)
                }
            }

            Section("Skill Families") {
                ForEach(families, id: \.self) { family in
                    NavigationLink {
                        SkillFamilyDetailView(family: family)
                    } label: {
                        HStack {
                            let heroNames = familyHeroNames(family)
                            SkillThumbnail(assetName: heroNames.first, assetNames: heroNames, size: 48)
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
                if let session = inProgress {
                    NavigationLink {
                        WorkoutSummaryView(session: session)
                    } label: {
                        Text("Open").bold()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start") {
                        sessionPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            refreshInProgress()
            refreshChart()
        }
        .onChange(of: sessions.count) { refreshChart() }
        .fullScreenCover(isPresented: $sessionPresented, onDismiss: refreshInProgress) {
            NavigationStack {
                WorkoutSessionView(workoutCode: workoutCode, services: services)
            }
            .keyboardDoneToolbar()
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
                if session.endedAt == nil {
                    Text("In Progress · \(progressPercent(session))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            CompletionChip(percent: CompletionScorer.sessionPercent(session))
        }
    }

    private func familyHeroNames(_ family: CDSkillFamily) -> [String] {
        let skills = (family.absSkills as? Set<CDAbsSkill>) ?? []
        return skills.min { $0.depth < $1.depth }?.posterAssetNames ?? []
    }

    /// completed sets / (totalRounds × families). Matches
    /// `WorkoutSessionViewModel.totalRounds` (= 5).
    private func progressPercent(_ session: Session) -> Int {
        let total = 5 * families.count
        guard total > 0 else { return 0 }
        let done = session.orderedSetLogs.count
        return Int((Double(done) / Double(total) * 100).rounded())
    }

    private func refreshChart() {
        sessionPts = FamilyPercentChart.points(for: Array(sessions.reversed()))
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
