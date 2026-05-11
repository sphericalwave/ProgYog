//
//  WorkoutCompositeChart.swift
//  ProgYog
//

import SwiftUI
import Charts

struct WorkoutCompositeChart: View {
    struct FamilyAverage: Identifiable {
        let id = UUID()
        let familyName: String
        let order: Int16
        let avgRpt: Double
        let avgRpe: Double
        let avgRpd: Double
    }

    let families: [FamilyAverage]

    var body: some View {
        Chart {
            ForEach(families) { fam in
                BarMark(
                    x: .value("Family", "\(fam.order). \(fam.familyName)"),
                    y: .value("RPT", fam.avgRpt)
                )
                .foregroundStyle(by: .value("Metric", "RPT"))
                .position(by: .value("Metric", "RPT"))

                BarMark(
                    x: .value("Family", "\(fam.order). \(fam.familyName)"),
                    y: .value("RPE", fam.avgRpe)
                )
                .foregroundStyle(by: .value("Metric", "RPE"))
                .position(by: .value("Metric", "RPE"))

                BarMark(
                    x: .value("Family", "\(fam.order). \(fam.familyName)"),
                    y: .value("RPD", fam.avgRpd)
                )
                .foregroundStyle(by: .value("Metric", "RPD"))
                .position(by: .value("Metric", "RPD"))
            }
        }
        .chartYScale(domain: 0...10)
        .chartForegroundStyleScale([
            "RPT": Color.blue,
            "RPE": Color.orange,
            "RPD": Color.red,
        ])
        .chartLegend(position: .bottom)
        .frame(height: 240)
    }
}

extension WorkoutCompositeChart {
    static func averages(from logs: [SetLog]) -> [FamilyAverage] {
        let grouped = Dictionary(grouping: logs) { log -> String in
            log.absSkill?.skillFamily?.name ?? "Unknown"
        }
        return grouped
            .map { (name, group) -> FamilyAverage in
                let count = max(group.count, 1)
                let order = group.first?.absSkill?.skillFamily?.order ?? 0
                let rpt = Double(group.reduce(0) { $0 + Int($1.rpt) }) / Double(count)
                let rpe = Double(group.reduce(0) { $0 + Int($1.rpe) }) / Double(count)
                let rpd = Double(group.reduce(0) { $0 + Int($1.rpd) }) / Double(count)
                return FamilyAverage(familyName: name, order: order, avgRpt: rpt, avgRpe: rpe, avgRpd: rpd)
            }
            .sorted { $0.order < $1.order }
    }
}
