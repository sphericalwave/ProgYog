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
            ForEach(sessions, id: \.id) { session in
                NavigationLink(value: session.objectID) {
                    row(for: session)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(session)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete { offsets in
                offsets.map { sessions[$0] }.forEach(delete)
            }
        }
        .navigationTitle("History")
        .navigationDestination(for: NSManagedObjectID.self) { id in
            if let session = sessions.first(where: { $0.objectID == id }) {
                WorkoutSummaryView(session: session)
            }
        }
    }

    private func delete(_ session: Session) {
        moc.delete(session)
        services.coreData.save()
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
