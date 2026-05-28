//
//  WorkoutListView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct WorkoutListView: View {
    private let workoutCodes = WorkoutPalette.codes

    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "startedAt", ascending: false)]
    ) private var sessions: FetchedResults<Session>

    var body: some View {
        NavigationStack {
            List(workoutCodes, id: \.self) { code in
                NavigationLink(value: code) {
                    HStack(spacing: 10) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(WorkoutPalette.color(for: code))
                        Text(WorkoutLabel.display(forCode: code))
                            .font(.headline)
                        Spacer()
                        stats(for: code)
                        CompletionChip(
                            percent: CompletionScorer.lastSessionPercent(workoutCode: code, moc: moc),
                            caption: "last"
                        )
                        CompletionChip(
                            percent: CompletionScorer.allTimeBestSessionPercent(workoutCode: code, moc: moc),
                            caption: "best"
                        )
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

#if DEBUG
#Preview {
    WorkoutListView()
        .environmentObject(PreviewSupport.services)
        .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
