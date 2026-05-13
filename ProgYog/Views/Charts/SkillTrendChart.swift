//
//  SkillTrendChart.swift
//  ProgYog
//

import SwiftUI
import Charts

struct SkillTrendChart: View {
    let logs: [SetLog]
    let highlightSession: Session?

    init(logs: [SetLog], highlightSession: Session? = nil) {
        self.logs = logs
        self.highlightSession = highlightSession
    }

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

    private func isCurrent(_ log: SetLog) -> Bool {
        guard let s = highlightSession else { return false }
        return log.session == s
    }

    private func opacity(for log: SetLog) -> Double {
        guard highlightSession != nil else { return 1.0 }
        return isCurrent(log) ? 1.0 : 0.55
    }

    private var maxReps: Int {
        max(Int(logs.map(\.reps).max() ?? 0), 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ratingChart
            if !logs.isEmpty {
                repsChart
            }
        }
    }

    private var ratingChart: some View {
        Chart {
            ForEach(logs, id: \.id) { log in
                LineMark(
                    x: .value("Date", log.loggedAt),
                    y: .value("RPT", log.rpt)
                )
                .foregroundStyle(by: .value("Metric", Metric.rpt.rawValue))
                .opacity(opacity(for: log))

                LineMark(
                    x: .value("Date", log.loggedAt),
                    y: .value("RPE", log.rpe)
                )
                .foregroundStyle(by: .value("Metric", Metric.rpe.rawValue))
                .opacity(opacity(for: log))

                LineMark(
                    x: .value("Date", log.loggedAt),
                    y: .value("RPD", log.rpd)
                )
                .foregroundStyle(by: .value("Metric", Metric.rpd.rawValue))
                .opacity(opacity(for: log))

                if isCurrent(log) {
                    PointMark(
                        x: .value("Date", log.loggedAt),
                        y: .value("RPT", log.rpt)
                    )
                    .foregroundStyle(by: .value("Metric", Metric.rpt.rawValue))
                    .symbolSize(70)

                    PointMark(
                        x: .value("Date", log.loggedAt),
                        y: .value("RPE", log.rpe)
                    )
                    .foregroundStyle(by: .value("Metric", Metric.rpe.rawValue))
                    .symbolSize(70)

                    PointMark(
                        x: .value("Date", log.loggedAt),
                        y: .value("RPD", log.rpd)
                    )
                    .foregroundStyle(by: .value("Metric", Metric.rpd.rawValue))
                    .symbolSize(70)
                }
            }
        }
        .chartYScale(domain: 0...10)
        .chartForegroundStyleScale([
            Metric.rpt.rawValue: Metric.rpt.color,
            Metric.rpe.rawValue: Metric.rpe.color,
            Metric.rpd.rawValue: Metric.rpd.color,
        ])
        .chartLegend(position: .bottom)
        .frame(height: 200)
    }

    private var repsChart: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Reps")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Chart {
                ForEach(logs, id: \.id) { log in
                    BarMark(
                        x: .value("Date", log.loggedAt),
                        y: .value("Reps", Int(log.reps))
                    )
                    .foregroundStyle(Color.green.opacity(highlightSession == nil || isCurrent(log) ? 1.0 : 0.35))
                }
            }
            .chartYScale(domain: 0...maxReps)
            .frame(height: 80)
        }
    }
}
