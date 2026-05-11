//
//  SessionHistoryView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SessionHistoryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "startedAt", ascending: false)]
    ) private var sessions: FetchedResults<Session>

    var body: some View {
        List {
            if sessions.isEmpty {
                Text("No sessions yet. Start a workout to log your first set.")
                    .foregroundStyle(.secondary)
            }
            ForEach(sessions, id: \.id) { session in
                NavigationLink(value: session.objectID) {
                    row(for: session)
                }
            }
        }
        .navigationTitle("History")
        .navigationDestination(for: NSManagedObjectID.self) { id in
            if let session = sessions.first(where: { $0.objectID == id }) {
                WorkoutSummaryView(session: session)
            }
        }
    }

    @ViewBuilder
    private func row(for session: Session) -> some View {
        let setCount = session.orderedSetLogs.count
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Workout \(session.workoutCode)").font(.headline)
                Spacer()
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("\(setCount) set\(setCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
