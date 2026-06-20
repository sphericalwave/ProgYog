//
//  DashboardView.swift
//  ProgYog
//

import SwiftUI
import Charts
import CoreData

struct DashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "startedAt", ascending: false)]
    ) private var sessions: FetchedResults<Session>

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Finish a workout to see stats here.")
                )
            } else {
                statsList
            }
        }
        .navigationTitle("Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.accentColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
    }

    private var statsList: some View {
        let all = Array(sessions)
        let completion = Self.completionPoints(all)
        let weekly = Self.weeklyPoints(all)
        let monthly = Self.monthlyPoints(all)
        let total = Self.totalTimePoints(all)
        let avg = Self.avgTimePoints(all)

        return List {
            Section("Completion %") {
                CompletionChart(points: completion)
            }
            Section("Sessions per week") {
                VolumeChart(points: weekly, unit: .weekOfYear, labelFormat: .dateTime.month(.abbreviated).day())
            }
            Section("Sessions per month") {
                VolumeChart(points: monthly, unit: .month, labelFormat: .dateTime.month(.abbreviated))
            }
            Section("Total time on-mat per workout") {
                TimeChart(points: total)
            }
            Section("Average time per session") {
                TimeChart(points: avg)
            }
        }
        .listStyle(.grouped)
    }
}

// MARK: - Completion section

private struct CompletionPoint: Identifiable {
    let id: String
    let code: String
    let last: Double
    let best: Double?
    var label: String { code }
}

private struct CompletionChart: View {
    let points: [CompletionPoint]

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Workout", p.label),
                    y: .value("Last %", p.last)
                )
                .foregroundStyle(WorkoutPalette.color(for: p.code))
                .annotation(position: .top, alignment: .center) {
                    annotation(for: p)
                }

                if let best = p.best, best > p.last + 0.5 {
                    BarMark(
                        x: .value("Workout", p.label),
                        yStart: .value("Last", p.last),
                        yEnd: .value("Best", best)
                    )
                    .foregroundStyle(WorkoutPalette.color(for: p.code).opacity(0.25))
                }
            }
        }
        .chartYScale(domain: 0...100)
        .frame(height: 220)
    }

    @ViewBuilder
    private func annotation(for p: CompletionPoint) -> some View {
        VStack(spacing: 1) {
            Text("\(Int(p.last.rounded()))%")
                .font(.caption2.bold().monospacedDigit())
            if let best = p.best, best > p.last + 0.5 {
                Text("best \(Int(best.rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Volume sections

private struct VolumePoint: Identifiable {
    let id = UUID()
    let bucketStart: Date
    let count: Int
}

private struct VolumeChart: View {
    let points: [VolumePoint]
    let unit: Calendar.Component
    let labelFormat: Date.FormatStyle

    var body: some View {
        Chart(points) { p in
            BarMark(
                x: .value("Bucket", p.bucketStart, unit: unit),
                y: .value("Sessions", p.count)
            )
            .foregroundStyle(Color.accentColor)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: unit)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: labelFormat)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4, roundLowerBound: true, roundUpperBound: true))
        }
        .frame(height: 200)
    }
}

// MARK: - Time section

private struct TimePoint: Identifiable {
    let id: String
    let code: String
    let minutes: Int
}

private struct TimeChart: View {
    let points: [TimePoint]

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Workout", p.code),
                    y: .value("Minutes", p.minutes)
                )
                .foregroundStyle(WorkoutPalette.color(for: p.code))
                .annotation(position: .top) {
                    Text(formatted(p.minutes))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 200)
    }

    private func formatted(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

// MARK: - Aggregation

extension DashboardView {
    fileprivate static func completionPoints(_ sessions: [Session]) -> [CompletionPoint] {
        let grouped = Dictionary(grouping: sessions, by: \.workoutCode)
        return WorkoutPalette.codes.compactMap { code in
            let codeSessions = grouped[code] ?? []
            guard let last = codeSessions.first.flatMap({ CompletionScorer.sessionPercent($0) }) else {
                return nil
            }
            let best = codeSessions.compactMap { CompletionScorer.sessionPercent($0) }.max()
            return CompletionPoint(id: code, code: code, last: last, best: best)
        }
    }

    fileprivate static func weeklyPoints(_ sessions: [Session], now: Date = Date(), count: Int = 12) -> [VolumePoint] {
        bucketed(sessions, unit: .weekOfYear, now: now, count: count)
    }

    fileprivate static func monthlyPoints(_ sessions: [Session], now: Date = Date(), count: Int = 12) -> [VolumePoint] {
        bucketed(sessions, unit: .month, now: now, count: count)
    }

    private static func bucketed(_ sessions: [Session], unit: Calendar.Component, now: Date, count: Int) -> [VolumePoint] {
        let cal = Calendar.current
        guard let currentStart = cal.dateInterval(of: unit, for: now)?.start else { return [] }
        let buckets: [Date] = (0..<count).reversed().compactMap { i in
            cal.date(byAdding: unit, value: -i, to: currentStart)
        }
        let grouped = Dictionary(grouping: sessions) {
            cal.dateInterval(of: unit, for: $0.startedAt)?.start ?? .distantPast
        }
        return buckets.map { VolumePoint(bucketStart: $0, count: grouped[$0]?.count ?? 0) }
    }

    fileprivate static func totalTimePoints(_ sessions: [Session]) -> [TimePoint] {
        WorkoutPalette.codes.map { code in
            let seconds = secondsForCode(code, in: sessions)
            return TimePoint(id: code, code: code, minutes: Int((Double(seconds) / 60).rounded()))
        }
    }

    fileprivate static func avgTimePoints(_ sessions: [Session]) -> [TimePoint] {
        WorkoutPalette.codes.map { code in
            let codeSessions = sessions.filter { $0.workoutCode == code }
            guard !codeSessions.isEmpty else {
                return TimePoint(id: code, code: code, minutes: 0)
            }
            let seconds = codeSessions
                .flatMap { $0.orderedSetLogs }
                .reduce(0) { $0 + Int($1.durationSec) }
            let avgSec = Double(seconds) / Double(codeSessions.count)
            return TimePoint(id: code, code: code, minutes: Int((avgSec / 60).rounded()))
        }
    }

    private static func secondsForCode(_ code: String, in sessions: [Session]) -> Int {
        sessions
            .filter { $0.workoutCode == code }
            .flatMap { $0.orderedSetLogs }
            .reduce(0) { $0 + Int($1.durationSec) }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DashboardView()
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
