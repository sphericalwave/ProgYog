//
//  WorkoutFamilyCompletionChart.swift
//  ProgYog
//

import SwiftUI
import Charts

struct WorkoutFamilyCompletionChart: View {
    struct Point: Identifiable {
        let id = UUID()
        let familyName: String
        let order: Int16
        let percent: Double
    }

    let points: [Point]

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Family", "\(p.order). \(p.familyName)"),
                    y: .value("%", p.percent)
                )
                .foregroundStyle(tint(for: p.percent))
                .annotation(position: .top, alignment: .center) {
                    Text("\(Int(p.percent.rounded()))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYScale(domain: 0...100)
        .frame(height: 240)
    }

    private func tint(for percent: Double) -> Color {
        switch percent {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}

extension WorkoutFamilyCompletionChart {
    static func points(for session: Session) -> [Point] {
        let families = Set(session.orderedSetLogs.compactMap { $0.absSkill?.skillFamily })
        return families
            .compactMap { family -> Point? in
                guard let pct = CompletionScorer.familyPercent(in: session, family: family) else { return nil }
                return Point(familyName: family.name, order: family.order, percent: pct)
            }
            .sorted { $0.order < $1.order }
    }
}
