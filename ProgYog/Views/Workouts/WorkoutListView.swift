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

    @State private var histPts: [FamilyPercentChart.Point] = []
    @State private var lastPcts: [String: Double] = [:]
    @State private var bestPcts: [String: Double] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(workoutCodes, id: \.self) { code in
                        NavigationLink(value: code) {
                            workoutRow(for: code)
                        }
                    }
                } header: {
                    if !histPts.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("History")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                                .padding(.horizontal, 4)
                            FamilyPercentChart(points: histPts)
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 4)
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
            .onAppear { refreshScores() }
            .onChange(of: sessions.count) { refreshScores() }
        }
    }

    private func refreshScores() {
        let all = Array(sessions) // already loaded, sorted newest-first
        histPts = FamilyPercentChart.points(for: all.reversed())
        for code in workoutCodes {
            let codeSessions = all.filter { $0.workoutCode == code }
            lastPcts[code] = codeSessions.first.flatMap { CompletionScorer.sessionPercent($0) }
            bestPcts[code] = codeSessions.compactMap { CompletionScorer.sessionPercent($0) }.max()
        }
    }

    @ViewBuilder
    private func workoutRow(for code: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.fill")
                .foregroundColor(WorkoutPalette.color(for: code))
            Text(WorkoutLabel.display(forCode: code))
                .font(.headline)
            Spacer()
            stats(for: code)
            CompletionChip(percent: lastPcts[code], caption: "last")
            CompletionChip(percent: bestPcts[code], caption: "best")
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
