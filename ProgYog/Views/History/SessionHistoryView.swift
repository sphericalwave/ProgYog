//
//  SessionHistoryView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SessionHistoryView: View {
    @Environment(\.managedObjectContext) private var moc
    @EnvironmentObject private var services: AppServices

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "startedAt", ascending: false)]
    ) private var sessions: FetchedResults<Session>

    var body: some View {
        List {
            if sessions.isEmpty {
                Text("No sessions yet. Start a workout to log your first set.")
                    .foregroundStyle(.secondary)
            }
            ForEach(sessions, id: \.objectID) { session in
                NavigationLink(value: session.objectID) {
                    SessionRow(session: session)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
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
        .listStyle(.grouped)
        .navigationTitle("History")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.accentColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .navigationDestination(for: NSManagedObjectID.self) { id in
            if let session = sessions.first(where: { $0.objectID == id }) {
                WorkoutSummaryView(session: session)
            }
        }
    }

    private func delete(_ session: Session) {
        let snap = SessionRecovery.snapshot(session)
        let coreData = services.coreData
        services.undo.push(description: "1 session") {
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
        moc.delete(session)
        services.coreData.save()
    }
}

private struct SessionRow: View {
    @ObservedObject var session: Session

    @FetchRequest private var logs: FetchedResults<SetLog>

    init(session: Session) {
        self.session = session
        _logs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "roundIndex", ascending: true)],
            predicate: NSPredicate(format: "session == %@", session)
        )
    }

    var body: some View {
        if session.isDeleted || session.managedObjectContext == nil {
            EmptyView()
        } else {
            let setCount = logs.count
            let roundCount = Set(logs.map { $0.roundIndex }).count
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.workoutCode)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(WorkoutPalette.color(for: session.workoutCode).opacity(0.15))
                        .foregroundStyle(WorkoutPalette.color(for: session.workoutCode))
                        .clipShape(Capsule())
                    Text(WorkoutLabel.display(for: session)).font(.headline)
                    Spacer()
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(roundCount) round\(roundCount == 1 ? "" : "s") · \(setCount) set\(setCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SessionHistoryView()
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
