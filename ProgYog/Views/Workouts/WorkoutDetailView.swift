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
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Workout \(workoutCode)")
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
        }
        .alert("Discard session?", isPresented: $discardAlert) {
            Button("Discard", role: .destructive) {
                if let session = inProgress {
                    services.coreData.moc.delete(session)
                    services.coreData.save()
                }
                refreshInProgress()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove the in-progress session and all logged sets.")
        }
    }

    private func refreshInProgress() {
        inProgress = WorkoutSessionViewModel.inProgressSession(for: workoutCode, moc: services.coreData.moc)
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
