//
//  WorkoutListView.swift
//  ProgYog
//

import SwiftUI
import CoreData
import SwMediaKit

struct WorkoutListView: View {
    @EnvironmentObject private var services: AppServices

    private enum ChartMode { case history, roc }
    @State private var chartMode: ChartMode = .history

    var body: some View {
        let snap = services.stats.snapshot.workoutList
        NavigationStack {
            List {
                Section {
                    ForEach(snap.orderedCodes, id: \.self) { code in
                        NavigationLink(value: code) {
                            workoutRow(for: code, snap: snap)
                        }
                    }
                } header: {
                    if !snap.historyPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("History")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .textCase(nil)
                                    .padding(.horizontal, 4)
                                Spacer()
                                Picker("", selection: $chartMode) {
                                    Text("Progress").tag(ChartMode.history)
                                    Text("Rate").tag(ChartMode.roc)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                            if chartMode == .history {
                                FamilyPercentChart(points: snap.historyPoints)
                            } else {
                                FamilyPercentChart(points: snap.rocPoints, allowNegativeY: true)
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        //.padding(.bottom, 4)
                        .padding(.vertical, 20)
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            //.listStyle(.grouped)
            .navigationTitle("Workouts")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .navigationDestination(for: String.self) { code in
                WorkoutDetailView(workoutCode: code)
            }
        }
    }

    @ViewBuilder
    private func workoutRow(for code: String, snap: WorkoutListSnapshot) -> some View {
        HStack(spacing: 10) {
            SeriesThumbnail(code: code)
            Text(WorkoutLabel.display(forCode: code))
                .font(.headline)
            Spacer()
            stats(for: code, snap: snap)
            CompletionChip(percent: snap.lastPercentByCode[code], caption: "last")
            CompletionChip(percent: snap.bestPercentByCode[code], caption: "best")
        }
    }

    @ViewBuilder
    private func stats(for code: String, snap: WorkoutListSnapshot) -> some View {
        let count = snap.sessionCountByCode[code, default: 0]
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(count) \(count == 1 ? "session" : "sessions")")
                .font(.caption.bold())
                .monospacedDigit()
            if let last = snap.lastDateByCode[code] {
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

    private func color(for code: String) -> Color {
        switch code {
        case "A": return .red
        case "B": return .blue
        case "C": return .green
        case "D": return .purple
        case "E": return .orange
        default:  return .gray
        }
    }
}

/// Small cycling thumbnail for a workout row: flips through the series'
/// skills the same way `WorkoutDetailView`'s hero carousel does, bordered
/// in that series' color.
private struct SeriesThumbnail: View {
    let code: String

    @FetchRequest private var families: FetchedResults<CDSkillFamily>

    init(code: String) {
        self.code = code
        let req = NSFetchRequest<CDSkillFamily>(entityName: "CDSkillFamily")
        req.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        req.predicate = NSPredicate(format: "series == %@", code)
        req.relationshipKeyPathsForPrefetching = ["absSkills"]
        _families = FetchRequest(fetchRequest: req)
    }

    var body: some View {
        HeroGif(
            items: families.carouselSkills.map {
                HeroGif.Item(assetNames: $0.posterAssetNames, photos: $0.customPhotos)
            },
            borderColor: WorkoutPalette.color(for: code),
            showPauseButton: false
        )
        .frame(width: 48, height: 48)
    }
}

#if DEBUG
#Preview {
    WorkoutListView()
        .environmentObject(PreviewSupport.services)
        .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
