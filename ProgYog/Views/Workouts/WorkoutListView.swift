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

    private enum ChartMode { case history, roc }

    @State private var orderedCodes: [String] = WorkoutPalette.codes
    @State private var chartMode: ChartMode = .history
    @State private var histPts: [FamilyPercentChart.Point] = []
    @State private var rocPts: [FamilyPercentChart.Point] = []
    @State private var lastPcts: [String: Double] = [:]
    @State private var bestPcts: [String: Double] = [:]
    @State private var sessionCounts: [String: Int] = [:]
    @State private var lastDates: [String: Date] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(orderedCodes, id: \.self) { code in
                        NavigationLink(value: code) {
                            workoutRow(for: code)
                        }
                    }
                } header: {
                    if !histPts.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("History")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                                    .padding(.horizontal, 4)
                                Spacer()
                                Picker("", selection: $chartMode) {
                                    Text("Progress").tag(ChartMode.history)
                                    Text("Rate").tag(ChartMode.roc)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                            if chartMode == .history {
                                FamilyPercentChart(points: histPts)
                            } else {
                                FamilyPercentChart(points: rocPts, allowNegativeY: true)
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        //.padding(.bottom, 4)
                        .padding(.vertical, 20)
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            //.listStyle(.grouped)
            .navigationTitle("Workouts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .navigationDestination(for: String.self) { code in
                WorkoutDetailView(workoutCode: code)
            }
            .onAppear { refreshScores() }
            .onChange(of: sessions.count) { refreshScores() }
        }
    }

    private func refreshScores() {
        let all = Array(sessions) // already loaded, sorted newest-first
        // sessionPercent is expensive (sorts + faults logs per family). Compute
        // it once per session and reuse for the chart, last, and best below,
        // instead of recomputing ~3× per session on the main thread.
        var pctBySession: [NSManagedObjectID: Double] = [:]
        for s in all {
            if let p = CompletionScorer.sessionPercent(s) { pctBySession[s.objectID] = p }
        }
        let pts: [FamilyPercentChart.Point] = all.reversed().compactMap { s in
            guard let pct = pctBySession[s.objectID] else { return nil }
            return FamilyPercentChart.Point(percent: pct,
                                            barColor: WorkoutPalette.color(for: s.workoutCode),
                                            series: s.workoutCode)
        }
        histPts = pts
        rocPts = Self.rateOfChange(from: pts)
        let grouped = Dictionary(grouping: all, by: \.workoutCode)
        for code in workoutCodes {
            let codeSessions = grouped[code] ?? []
            lastPcts[code] = codeSessions.first.flatMap { pctBySession[$0.objectID] }
            bestPcts[code] = codeSessions.compactMap { pctBySession[$0.objectID] }.max()
            sessionCounts[code] = codeSessions.count
            lastDates[code] = codeSessions.first?.startedAt
        }
        let codes = workoutCodes
        if let last = all.first, let idx = codes.firstIndex(of: last.workoutCode) {
            let startIdx = last.endedAt == nil ? idx : (idx + 1) % codes.count
            orderedCodes = Array(codes[startIdx...]) + Array(codes[..<startIdx])
        } else {
            orderedCodes = codes
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
        let count = sessionCounts[code, default: 0]
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(count) \(count == 1 ? "session" : "sessions")")
                .font(.caption.bold())
                .monospacedDigit()
            if let last = lastDates[code] {
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

    private static func rateOfChange(from pts: [FamilyPercentChart.Point]) -> [FamilyPercentChart.Point] {
        var lastPct: [String: Double] = [:]
        var result: [FamilyPercentChart.Point] = []
        for p in pts {
            let key = p.series.isEmpty ? "_" : p.series
            if let prev = lastPct[key] {
                result.append(.init(percent: p.percent - prev, barColor: p.barColor, series: p.series))
            }
            lastPct[key] = p.percent
        }
        return result
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
