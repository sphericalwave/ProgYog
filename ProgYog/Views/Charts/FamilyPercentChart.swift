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
    struct Point: Identifiable {
        let id = UUID()
        let percent: Double
        var barColor: Color? = nil
        var series: String = ""
    }

    let points: [Point]
    var compact: Bool = false

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
        guard !vals.isEmpty else { return 0...100 }
        let lo = max(0, (vals.min()! - 10).rounded(.down))
        let hi = min(100, (vals.max()! + 5).rounded(.up))
        return lo...max(hi, lo + 1)
    }

    var body: some View {
        let es = entries
        let floor = yDomain.lowerBound
        Chart {
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
        .frame(height: compact ? 36 : 160)
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
