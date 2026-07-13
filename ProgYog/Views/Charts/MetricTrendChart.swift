//
//  MetricTrendChart.swift
//  ProgYog
//

import SwiftUI
import Charts

/// CatmullRom line chart of an arbitrary per-session metric (reps, RPE, RPD, ...),
/// oldest → newest. Same visual language as `FamilyPercentChart` but generic over
/// value range instead of being pinned to a 0...100 percent domain.
struct MetricTrendChart: View {
    struct Point: Identifiable, Sendable, Codable {
        let id = UUID()
        let value: Double
        var barColor: Color? = nil
        var series: String = ""

        private enum CodingKeys: String, CodingKey { case value, series }

        init(value: Double, barColor: Color? = nil, series: String = "") {
            self.value = value
            self.barColor = barColor
            self.series = series
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            value = try c.decode(Double.self, forKey: .value)
            series = try c.decode(String.self, forKey: .series)
            barColor = WorkoutPalette.color(for: series)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(value, forKey: .value)
            try c.encode(series, forKey: .series)
        }
    }

    let points: [Point]
    var compact: Bool = false

    private struct Entry: Identifiable {
        let id = UUID()
        let x: Int
        let series: String
        let value: Double
        let color: Color
    }

    private var entries: [Entry] {
        var counters: [String: Int] = [:]
        return points.map { p in
            let s = p.series.isEmpty ? "_" : p.series
            let idx = counters[s, default: 0]
            counters[s] = idx + 1
            return Entry(x: idx, series: s, value: p.value,
                         color: p.barColor ?? .secondary)
        }
    }

    private var isMultiSeries: Bool {
        Set(points.map(\.series)).count > 1
    }

    private var yDomain: ClosedRange<Double> {
        let vals = points.map(\.value)
        guard !vals.isEmpty else { return 0...10 }
        let hi = vals.max()!
        let pad = max(1, hi * 0.15)
        return 0...(hi + pad)
    }

    var body: some View {
        let es = entries
        Chart {
            if isMultiSeries {
                ForEach(es) { e in
                    LineMark(x: .value("n", e.x), y: .value("value", e.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(by: .value("s", e.series))
                }
                if !compact {
                    ForEach(es) { e in
                        PointMark(x: .value("n", e.x), y: .value("value", e.value))
                            .foregroundStyle(by: .value("s", e.series))
                            .symbolSize(30)
                    }
                }
            } else {
                ForEach(es) { e in
                    AreaMark(x: .value("n", e.x),
                             yStart: .value("base", yDomain.lowerBound),
                             yEnd: .value("value", e.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.secondary.opacity(0.08))
                }
                ForEach(es) { e in
                    LineMark(x: .value("n", e.x), y: .value("value", e.value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                if !compact {
                    ForEach(es) { e in
                        PointMark(x: .value("n", e.x), y: .value("value", e.value))
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
