//
//  FamilyPercentChart.swift
//  ProgYog

import SwiftUI
import Charts
import CoreData

/// Bar chart of completion % per workout instance, oldest → newest left → right.
/// `compact: true` hides axes and shrinks height for list-row use.
struct FamilyPercentChart: View {
    struct Point: Identifiable {
        let id = UUID()
        let percent: Double
        var barColor: Color? = nil
    }

    let points: [Point]
    var compact: Bool = false

    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { idx, p in
                BarMark(
                    x: .value("Session", String(idx)),
                    y: .value("%", p.percent),
                    width: .ratio(0.85)
                )
                .foregroundStyle(p.barColor ?? tint(for: p.percent))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis(compact ? .hidden : .automatic)
        .padding(.horizontal, 8)
        .frame(height: compact ? 36 : 160)
    }

    private func tint(for percent: Double) -> Color {
        switch percent {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
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
    /// Passes workout-palette color per bar when no family is specified.
    static func points(for sessions: [Session], family: CDSkillFamily? = nil) -> [Point] {
        sessions.compactMap { sess in
            let pct = family != nil
                ? CompletionScorer.familyPercent(in: sess, family: family!)
                : CompletionScorer.sessionPercent(sess)
            guard let pct else { return nil }
            let color: Color? = family == nil ? WorkoutPalette.color(for: sess.workoutCode) : nil
            return Point(percent: pct, barColor: color)
        }
    }
}
