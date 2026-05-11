//
//  HRCurveChart.swift
//  ProgYog
//

import SwiftUI
import Charts

struct HRCurveChart: View {
    let samples: [HRSample]

    var body: some View {
        Chart(samples, id: \.objectID) { s in
            LineMark(
                x: .value("Time (s)", s.t),
                y: .value("BPM", Int(s.bpm))
            )
            .foregroundStyle(.red)
            .interpolationMethod(.monotone)
        }
        .chartXScale(domain: 0...60)
        .frame(height: 140)
    }
}
