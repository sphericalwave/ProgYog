//
//  FamilyPercentChart.swift
//  ProgYog

import SwiftUI
import Charts
import CoreData

/// CatmullRom line chart of completion % per session, oldest → newest.
/// When points carry distinct `series` values (one per workout code) separate
/// coloured lines are drawn. `compact: true` hides axes and shrinks height.
struct FamilyPercentChart: View {
    struct Point: Identifiable, Sendable, Codable {
        let id = UUID()
        let percent: Double
        var barColor: Color? = nil
        var series: String = ""

        // `barColor` is a pure function of `series` (see WorkoutPalette) —
        // excluded from the persisted cache and recomputed on decode
        // instead of serializing a Color (which isn't Codable).
        private enum CodingKeys: String, CodingKey { case percent, series }

        init(percent: Double, barColor: Color? = nil, series: String = "") {
            self.percent = percent
            self.barColor = barColor
            self.series = series
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            percent = try c.decode(Double.self, forKey: .percent)
            series = try c.decode(String.self, forKey: .series)
            barColor = WorkoutPalette.color(for: series)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(percent, forKey: .percent)
            try c.encode(series, forKey: .series)
        }
    }

    let points: [Point]
    var compact: Bool = false
    var allowNegativeY: Bool = false

    // Pre-processed entry: x is the index within its own series so every
    // workout's line starts at 0 and grows independently.
    private struct Entry: Identifiable {
        let id = UUID()
        let x: Int
        let series: String
        let percent: Double
        let color: Color
    }

    private func tint(for percent: Double) -> Color {
        switch percent {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    private var entries: [Entry] {
        var counters: [String: Int] = [:]
        return points.map { p in
            let s = p.series.isEmpty ? "_" : p.series
            let idx = counters[s, default: 0]
            counters[s] = idx + 1
            return Entry(x: idx, series: s, percent: p.percent,
                         color: p.barColor ?? tint(for: p.percent))
        }
    }

    private var isMultiSeries: Bool {
        Set(points.map(\.series)).count > 1
    }

    private var yDomain: ClosedRange<Double> {
        let vals = points.map(\.percent)
        guard !vals.isEmpty else { return allowNegativeY ? -20...20 : 0...100 }
        if allowNegativeY {
            let lo = (vals.min()! - 5).rounded(.down)
            let hi = (vals.max()! + 5).rounded(.up)
            return lo...max(hi, lo + 1)
        }
        let lo = max(0, (vals.min()! - 10).rounded(.down))
        let hi = min(100, (vals.max()! + 5).rounded(.up))
        return lo...max(hi, lo + 1)
    }

    var body: some View {
        let es = entries
        let floor = yDomain.lowerBound
        Chart {
            if allowNegativeY {
                RuleMark(y: .value("zero", 0))
                    .foregroundStyle(.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            if isMultiSeries {
                ForEach(es) { e in
                    LineMark(x: .value("n", e.x), y: .value("%", e.percent))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("s", e.series))
                }
                if !compact {
                    ForEach(es) { e in
                        PointMark(x: .value("n", e.x), y: .value("%", e.percent))
                            .foregroundStyle(by: .value("s", e.series))
                            .symbolSize(30)
                    }
                }
            } else {
                ForEach(es) { e in
                    AreaMark(x: .value("n", e.x),
                             yStart: .value("base", floor),
                             yEnd: .value("%", e.percent))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.secondary.opacity(0.08))
                }
                ForEach(es) { e in
                    LineMark(x: .value("n", e.x), y: .value("%", e.percent))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                if !compact {
                    ForEach(es) { e in
                        PointMark(x: .value("n", e.x), y: .value("%", e.percent))
                            .foregroundStyle(e.color)
                            .symbolSize(40)
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            "A": WorkoutPalette.color(for: "A"),
            "B": WorkoutPalette.color(for: "B"),
            "C": WorkoutPalette.color(for: "C"),
            "D": WorkoutPalette.color(for: "D"),
            "E": WorkoutPalette.color(for: "E"),
            "_": Color.secondary
        ] as KeyValuePairs<String, Color>)
        .chartLegend(isMultiSeries && !compact ? .automatic : .hidden)
        .chartYScale(domain: yDomain)
        .chartXAxis(.hidden)
        .chartYAxis(compact ? .hidden : .automatic)
        .padding(.horizontal, 8)
        .frame(height: compact ? 36 : 234)
    }
}

extension FamilyPercentChart {
    /// Per-session family % for a skill family, oldest first.
    static func points(for family: CDSkillFamily) -> [Point] {
        let skills = (family.absSkills as? Set<CDAbsSkill>) ?? []
        let allLogs = skills.flatMap { ($0.setLogs as? Set<SetLog>) ?? [] }
        let sessions = Array(Set(allLogs.compactMap { $0.session }))
            .sorted { $0.startedAt < $1.startedAt }
        return sessions.compactMap { sess in
            guard let pct = CompletionScorer.familyPercent(in: sess, family: family) else { return nil }
            return Point(percent: pct)
        }
    }

    /// Per-session overall % for a list of sessions, oldest first.
    /// Sets `series` to the workout code so per-workout lines can be drawn.
    static func points(for sessions: [Session], family: CDSkillFamily? = nil) -> [Point] {
        sessions.compactMap { sess in
            let pct = family != nil
                ? CompletionScorer.familyPercent(in: sess, family: family!)
                : CompletionScorer.sessionPercent(sess)
            guard let pct else { return nil }
            let color: Color? = family == nil ? WorkoutPalette.color(for: sess.workoutCode) : nil
            let series: String = family == nil ? sess.workoutCode : ""
            return Point(percent: pct, barColor: color, series: series)
        }
    }
}
