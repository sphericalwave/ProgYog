//
//  DashboardView.swift
//  ProgYog
//

import SwiftUI
import Charts
import CoreData

struct DashboardView: View {
    @EnvironmentObject private var services: AppServices
    @State private var store: DashboardStatsStore?

    var body: some View {
        Group {
            if let store {
                if !store.snapshot.hasSessions {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Finish a workout to see stats here.")
                    )
                } else {
                    statsList(store.snapshot)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.accentColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .task {
            if store == nil {
                store = DashboardStatsStore(container: services.coreData.container)
            }
        }
    }

    private func statsList(_ snap: DashboardSnapshot) -> some View {
        List {
            Section("Completion %") {
                CompletionChart(points: snap.completion)
            }
            Section("Sessions per week") {
                VolumeChart(points: snap.weekly, unit: .weekOfYear,
                           labelFormat: .dateTime.month(.abbreviated).day())
            }
            Section("Sessions per month") {
                VolumeChart(points: snap.monthly, unit: .month,
                           labelFormat: .dateTime.month(.abbreviated))
            }
            Section("Total time on-mat per workout") {
                TimeChart(points: snap.total)
            }
            Section("Average time per session") {
                TimeChart(points: snap.avg)
            }
        }
        .listStyle(.grouped)
    }
}

// MARK: - Completion section

private struct CompletionChart: View {
    let points: [CompletionPoint]

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Workout", p.label),
                    y: .value("Last %", p.last)
                )
                .foregroundStyle(WorkoutPalette.color(for: p.code))
                .annotation(position: .top, alignment: .center) {
                    annotation(for: p)
                }

                if let best = p.best, best > p.last + 0.5 {
                    BarMark(
                        x: .value("Workout", p.label),
                        yStart: .value("Last", p.last),
                        yEnd: .value("Best", best)
                    )
                    .foregroundStyle(WorkoutPalette.color(for: p.code).opacity(0.25))
                }
            }
        }
        .chartYScale(domain: 0...100)
        .frame(height: 220)
    }

    @ViewBuilder
    private func annotation(for p: CompletionPoint) -> some View {
        VStack(spacing: 1) {
            Text("\(Int(p.last.rounded()))%")
                .font(.caption2.bold().monospacedDigit())
            if let best = p.best, best > p.last + 0.5 {
                Text("best \(Int(best.rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Volume sections

private struct VolumeChart: View {
    let points: [VolumePoint]
    let unit: Calendar.Component
    let labelFormat: Date.FormatStyle

    var body: some View {
        Chart(points) { p in
            BarMark(
                x: .value("Bucket", p.bucketStart, unit: unit),
                y: .value("Sessions", p.count)
            )
            .foregroundStyle(Color.accentColor)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: unit)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: labelFormat)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4, roundLowerBound: true, roundUpperBound: true))
        }
        .frame(height: 200)
    }
}

// MARK: - Time section

private struct TimeChart: View {
    let points: [TimePoint]

    var body: some View {
        Chart {
            ForEach(points) { p in
                BarMark(
                    x: .value("Workout", p.code),
                    y: .value("Minutes", p.minutes)
                )
                .foregroundStyle(WorkoutPalette.color(for: p.code))
                .annotation(position: .top) {
                    Text(formatted(p.minutes))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 200)
    }

    private func formatted(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DashboardView()
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
