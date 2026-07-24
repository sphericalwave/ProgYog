//
//  WorkoutDetailView.swift
//  ProgYog
//

import SwiftUI
import SwKeyboard
import CoreData
import SwMediaKit
import Charts

struct WorkoutDetailView: View {
    let workoutCode: String

    @EnvironmentObject private var services: AppServices
    @State private var sessionPresented = false
    @State private var inProgress: Session?

    @FetchRequest private var families: FetchedResults<CDSkillFamily>
    @FetchRequest private var setLogs: FetchedResults<SetLog>
    @FetchRequest private var sessions: FetchedResults<Session>

    @State private var trendMode: TrendMode = .progress
    @State private var selectedMetric: SkillTrendChart.Metric? = .rpt

    @State private var techniqueTrend: [MetricTrendChart.Point] = []
    @State private var discomfortTrend: [MetricTrendChart.Point] = []
    @State private var effortTrend: [MetricTrendChart.Point] = []

    private enum TrendMode { case progress, rate }

    init(workoutCode: String) {
        self.workoutCode = workoutCode
        let familiesReq = NSFetchRequest<CDSkillFamily>(entityName: "CDSkillFamily")
        familiesReq.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        familiesReq.predicate = NSPredicate(format: "series == %@", workoutCode)
        familiesReq.relationshipKeyPathsForPrefetching = ["absSkills"]
        _families = FetchRequest(fetchRequest: familiesReq)
        _setLogs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: false)],
            predicate: NSPredicate(format: "absSkill.skillFamily.series == %@", workoutCode)
        )
        _sessions = FetchRequest<Session>(
            sortDescriptors: [NSSortDescriptor(key: "startedAt", ascending: false)],
            predicate: NSPredicate(format: "workoutCode == %@", workoutCode)
        )
    }

    var body: some View {
        List {
            if !carouselSkills.isEmpty {
                Section {
                    heroCarousel
                        .padding(.vertical, 4)
                    WorkoutStatBadge(
                        title: WorkoutLabel.display(forCode: workoutCode),
                        percent: latestSession.flatMap(CompletionScorer.sessionPercent),
                        dynamicRounds: dynamicRoundCount,
                        isometricRounds: isometricRoundCount
                    )
                }
            }

            if !sessions.isEmpty {
                Section("History") {
                    Group {
                        if let selectedMetric {
                            MetricTrendChart(points: displayTrend(for: selectedMetric))
                        } else {
                            overlayTrendChart
                        }
                    }
                    .padding(.vertical, 4)
                    .overlay(alignment: .topTrailing) {
                        Picker("", selection: $trendMode) {
                            Text("Progress").tag(TrendMode.progress)
                            Text("Rate").tag(TrendMode.rate)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                        .padding(6)
                    }
                    Picker("", selection: $selectedMetric) {
                        Text("Technique").tag(SkillTrendChart.Metric?.some(.rpt))
                        Text("Discomfort").tag(SkillTrendChart.Metric?.some(.rpd))
                        Text("Effort").tag(SkillTrendChart.Metric?.some(.rpe))
                        Text("Overlay").tag(SkillTrendChart.Metric?.none)
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section("Skill Families") {
                ForEach(families, id: \.self) { family in
                    NavigationLink {
                        SkillFamilyDetailView(family: family)
                    } label: {
                        HStack {
                            let hero = (family.absSkills as? Set<CDAbsSkill>)?.min { $0.depth < $1.depth }
                            let heroNames = hero?.posterAssetNames ?? []
                            PosterThumbnail(assetName: heroNames.first, assetNames: heroNames,
                                           photos: hero?.customPhotos ?? [], size: 48,
                                           borderColor: seriesColor)
                            Text("\(family.order).")
                                .foregroundStyle(.secondary)
                            Text(family.name)
                            Spacer()
                            stats(for: family)
                            CompletionChip(
                                percent: CompletionScorer.allTimeBestFamilyPercent(family),
                                caption: "best"
                            )
                        }
                    }
                }
            }

            if !sessions.isEmpty {
                Section("Session History") {
                    ForEach(sessions, id: \.objectID) { session in
                        NavigationLink {
                            WorkoutSummaryView(session: session)
                        } label: {
                            sessionRow(session)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                _ = services.coreData.duplicateSession(session)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(WorkoutLabel.display(forCode: workoutCode))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if let session = inProgress {
                    NavigationLink {
                        WorkoutSummaryView(session: session)
                    } label: {
                        Text("Open").bold()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start") {
                        sessionPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            refreshInProgress()
            refreshChart()
        }
        .onChange(of: sessions.count) { refreshChart() }
        .fullScreenCover(isPresented: $sessionPresented, onDismiss: refreshInProgress) {
            NavigationStack {
                WorkoutSessionView(workoutCode: workoutCode, services: services)
            }
            .doneKeyboardToolbar()
        }
    }

    private func refreshInProgress() {
        inProgress = WorkoutSessionViewModel.inProgressSession(for: workoutCode, moc: services.coreData.moc)
    }

    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.bold())
                Text("\(session.orderedSetLogs.count) sets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if session.endedAt == nil {
                    Text("In Progress · \(progressPercent(session))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            CompletionChip(percent: CompletionScorer.sessionPercent(session))
        }
    }


    /// completed sets / (totalRounds × families). Matches
    /// `WorkoutSessionViewModel.totalRounds` (= 5).
    private func progressPercent(_ session: Session) -> Int {
        let total = 5 * families.count
        guard total > 0 else { return 0 }
        let done = session.orderedSetLogs.count
        return Int((Double(done) / Double(total) * 100).rounded())
    }

    private func refreshChart() {
        techniqueTrend = ratingTrend(\.rpt, color: SkillTrendChart.Metric.rpt.color)
        discomfortTrend = ratingTrend(\.rpd, color: SkillTrendChart.Metric.rpd.color)
        effortTrend = ratingTrend(\.rpe, color: SkillTrendChart.Metric.rpe.color)
    }

    /// Per-session average rating, oldest first. Skips sessions with no
    /// logs — the same guard for every metric, so the three trend arrays
    /// stay index-aligned with each other.
    private func ratingTrend(_ rating: KeyPath<SetLog, Int16>, color: Color) -> [MetricTrendChart.Point] {
        sessions.reversed().compactMap { session in
            let logs = session.orderedSetLogs
            guard !logs.isEmpty else { return nil }
            let avg = Double(logs.reduce(0) { $0 + Int($1[keyPath: rating]) }) / Double(logs.count)
            return MetricTrendChart.Point(value: avg, barColor: color)
        }
    }

    /// Session-over-session delta of a trend array. Single-series — this
    /// view only ever covers one workout code, so no per-series keying is
    /// needed (unlike `WorkoutListView`'s multi-code rate-of-change).
    private func rateOfChange(_ points: [MetricTrendChart.Point]) -> [MetricTrendChart.Point] {
        guard points.count > 1 else { return [] }
        return zip(points, points.dropFirst()).map { prev, cur in
            MetricTrendChart.Point(value: cur.value - prev.value, barColor: cur.barColor)
        }
    }

    private func displayTrend(for metric: SkillTrendChart.Metric) -> [MetricTrendChart.Point] {
        let raw: [MetricTrendChart.Point]
        switch metric {
        case .rpt: raw = techniqueTrend
        case .rpd: raw = discomfortTrend
        case .rpe: raw = effortTrend
        }
        return trendMode == .progress ? raw : rateOfChange(raw)
    }

    /// All three metrics overlaid, colored the same as `SkillTrendChart`.
    @ViewBuilder
    private var overlayTrendChart: some View {
        let technique = displayTrend(for: .rpt)
        let discomfort = displayTrend(for: .rpd)
        let effort = displayTrend(for: .rpe)
        Chart {
            ForEach(Array(technique.enumerated()), id: \.offset) { idx, p in
                LineMark(x: .value("n", idx), y: .value("Technique", p.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value("Metric", SkillTrendChart.Metric.rpt.rawValue))
            }
            ForEach(Array(discomfort.enumerated()), id: \.offset) { idx, p in
                LineMark(x: .value("n", idx), y: .value("Discomfort", p.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value("Metric", SkillTrendChart.Metric.rpd.rawValue))
            }
            ForEach(Array(effort.enumerated()), id: \.offset) { idx, p in
                LineMark(x: .value("n", idx), y: .value("Effort", p.value))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value("Metric", SkillTrendChart.Metric.rpe.rawValue))
            }
        }
        .chartForegroundStyleScale([
            SkillTrendChart.Metric.rpt.rawValue: SkillTrendChart.Metric.rpt.color,
            SkillTrendChart.Metric.rpe.rawValue: SkillTrendChart.Metric.rpe.color,
            SkillTrendChart.Metric.rpd.rawValue: SkillTrendChart.Metric.rpd.color,
        ])
        .chartLegend(position: .bottom)
        .chartXAxis(.hidden)
        .padding(.horizontal, 8)
        .frame(height: 234)
    }

    private var carouselSkills: [CDAbsSkill] { families.carouselSkills }

    private var seriesColor: Color { WorkoutPalette.color(for: workoutCode) }

    /// Most recently started session — `sessions` is sorted newest first.
    private var latestSession: Session? { sessions.first }

    private var dynamicRoundCount: Int {
        latestSession?.orderedSetLogs.filter { !$0.isometric }.count ?? 0
    }

    private var isometricRoundCount: Int {
        latestSession?.orderedSetLogs.filter(\.isometric).count ?? 0
    }

    private var heroCarousel: some View {
        HeroGif(
            items: carouselSkills.map {
                HeroGif.Item(assetNames: $0.posterAssetNames, photos: $0.customPhotos)
            },
            borderColor: seriesColor
        )
    }

    @ViewBuilder
    private func stats(for family: CDSkillFamily) -> some View {
        let logs = setLogs.filter { $0.absSkill?.skillFamily == family }
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(logs.count) \(logs.count == 1 ? "set" : "sets")")
                .font(.caption.bold())
                .monospacedDigit()
            if let last = logs.first?.loggedAt {
                Text(last.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("never")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        WorkoutDetailView(workoutCode: "A")
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
