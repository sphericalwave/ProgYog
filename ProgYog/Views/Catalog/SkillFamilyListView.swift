//
//  SkillFamilyListView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillFamilyListView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(key: "series", ascending: true),
            NSSortDescriptor(key: "order", ascending: true),
        ]
    ) private var families: FetchedResults<CDSkillFamily>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: false)]
    ) private var setLogs: FetchedResults<SetLog>

    private var groupedSeries: [(series: String, families: [CDSkillFamily])] {
        let dict = Dictionary(grouping: families) { $0.series }
        return dict.keys.sorted().map { key in
            (series: key, families: dict[key]!.sorted { $0.order < $1.order })
        }
    }

    var body: some View {
        List {
            ForEach(groupedSeries, id: \.series) { group in
                Section("Workout \(group.series)") {
                    ForEach(group.families, id: \.self) { family in
                        NavigationLink {
                            SkillFamilyDetailView(family: family)
                        } label: {
                            HStack {
                                Text("\(family.order).")
                                    .foregroundStyle(.secondary)
                                Text(family.name)
                                Spacer()
                                stats(for: family)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Skill Families")
    }

    // MARK: helpers below

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
        SkillFamilyListView()
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
