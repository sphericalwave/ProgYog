//
//  FamilyPercentChart.swift
//  ProgYog

import SwiftUI
import Charts
import CoreData

/// Bar chart of family completion % per workout session.
/// `compact: true` hides axes and shrinks height for list-row use.
struct FamilyPercentChart: View {
    struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let percent: Double
    }

    let points: [Point]
    var compact: Bool = false

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Session", p.date, unit: .day),
                    y: .value("%", p.percent)
                )
                .foregroundStyle(tint(for: p.percent))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(compact ? .hidden : .automatic)
        .chartYAxis(compact ? .hidden : .automatic)
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
    static func points(for family: CDSkillFamily) -> [Point] {
        let skills = (family.absSkills as? Set<CDAbsSkill>) ?? []
        let allLogs = skills.flatMap { ($0.setLogs as? Set<SetLog>) ?? [] }
        let sessions = Array(Set(allLogs.compactMap { $0.session }))
            .sorted { $0.startedAt < $1.startedAt }
        return sessions.compactMap { sess in
            guard let pct = CompletionScorer.familyPercent(in: sess, family: family) else { return nil }
            return Point(date: sess.startedAt, percent: pct)
        }
    }
}
