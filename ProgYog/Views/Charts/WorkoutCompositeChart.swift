//
//  WorkoutCompositeChart.swift
//  ProgYog
//

import SwiftUI
import Charts
import CoreData

struct WorkoutCompositeChart: View {
    let logs: [SetLog]

    private struct Point: Identifiable {
        let id: NSManagedObjectID
        let label: String
        let percent: Double
    }

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Set", p.label),
                    y: .value("%", p.percent)
                )
                .foregroundStyle(tint(for: p.percent))
                .annotation(position: .top, alignment: .center) {
                    Text("\(Int(p.percent.rounded()))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartYScale(domain: 0...100)
        .frame(height: 220)
    }

    private var points: [Point] {
        let romMin = Double(CompletionScorer.romMin)
        let maxDepth = Double(logs.first?.absSkill?.skillFamily?.maxDepth ?? 0)
        guard maxDepth > 0 else { return [] }
        return logs.map { log in
            let depth = Double(log.absSkill?.depth ?? 0)
            let romFraction = romMin > 0
                ? min(1.0, max(0.0, Double(log.rom) / romMin))
                : 0.0
            let achieved = max(0.0, depth - 1.0) + romFraction
            let pct = min(100, (achieved / maxDepth) * 100)
            return Point(
                id: log.objectID,
                label: "R\(log.roundIndex + 1)·\(log.orderInRound + 1)",
                percent: pct
            )
        }
    }

    private func tint(for percent: Double) -> Color {
        switch percent {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}
