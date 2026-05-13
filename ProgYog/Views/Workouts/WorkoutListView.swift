//
//  WorkoutListView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct WorkoutListView: View {
    private let workoutCodes = ["A", "B", "C", "D", "E"]

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "startedAt", ascending: false)]
    ) private var sessions: FetchedResults<Session>

    var body: some View {
        NavigationStack {
            List(workoutCodes, id: \.self) { code in
                NavigationLink(value: code) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(color(for: code))
                        Text("Workout \(code)")
                            .font(.headline)
                        Spacer()
                        stats(for: code)
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Workouts")
            .navigationDestination(for: String.self) { code in
                WorkoutDetailView(workoutCode: code)
            }
        }
    }

    @ViewBuilder
    private func stats(for code: String) -> some View {
        let codeSessions = sessions.filter { $0.workoutCode == code }
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(codeSessions.count) \(codeSessions.count == 1 ? "session" : "sessions")")
                .font(.caption.bold())
                .monospacedDigit()
            if let last = codeSessions.first?.startedAt {
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

    private func color(for code: String) -> Color {
        switch code {
        case "A": return .red
        case "B": return .blue
        case "C": return .green
        case "D": return .purple
        case "E": return .orange
        default:  return .gray
        }
    }
}
