//
//  SkillTrendChart.swift
//  ProgYog
//

import SwiftUI
import Charts

struct SkillTrendChart: View {
    let logs: [SetLog]

    enum Metric: String, CaseIterable, Identifiable {
        case rpt = "RPT", rpe = "RPE", rpd = "RPD"
        var id: String { rawValue }
        var color: Color {
            switch self {
            case .rpt: return .blue
            case .rpe: return .orange
            case .rpd: return .red
            }
        }
    }

    var body: some View {
        Chart {
            ForEach(logs, id: \.id) { log in
                LineMark(
                    x: .value("Date", log.loggedAt),
                    y: .value("RPT", log.rpt)
                )
                .foregroundStyle(by: .value("Metric", Metric.rpt.rawValue))

                LineMark(
                    x: .value("Date", log.loggedAt),
                    y: .value("RPE", log.rpe)
                )
                .foregroundStyle(by: .value("Metric", Metric.rpe.rawValue))

                LineMark(
                    x: .value("Date", log.loggedAt),
                    y: .value("RPD", log.rpd)
                )
                .foregroundStyle(by: .value("Metric", Metric.rpd.rawValue))
            }
        }
        .chartYScale(domain: 0...10)
        .chartForegroundStyleScale([
            Metric.rpt.rawValue: Metric.rpt.color,
            Metric.rpe.rawValue: Metric.rpe.color,
            Metric.rpd.rawValue: Metric.rpd.color,
        ])
        .chartLegend(position: .bottom)
        .frame(height: 220)
    }
}
