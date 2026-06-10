//
//  SkillFamilyDetailView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillFamilyDetailView: View {
    let family: CDSkillFamily

    @FetchRequest private var skills: FetchedResults<CDAbsSkill>
    @Environment(\.managedObjectContext) private var moc
    @EnvironmentObject private var services: AppServices
    @State private var addVariantPresented = false

    init(family: CDSkillFamily) {
        self.family = family
        _skills = FetchRequest<CDAbsSkill>(
            sortDescriptors: [NSSortDescriptor(key: "depth", ascending: true)],
            predicate: NSPredicate(format: "skillFamily == %@", family)
        )
    }

    private var sessionPoints: [FamilyPercentChart.Point] {
        FamilyPercentChart.points(for: family)
    }


    var body: some View {
        List {
            let pts = sessionPoints
            if !pts.isEmpty {
                Section("History") {
                    FamilyPercentChart(points: pts)
                        .padding(.vertical, 4)
                }
            }

            ForEach(skills, id: \.objectID) { skill in
                NavigationLink {
                    SkillDetailView(skill: skill)
                } label: {
                    HStack(spacing: 12) {
                        SkillThumbnail(
                            assetName: skill.posterAssetName,
                            assetNames: skill.posterAssetNames,
                            photoData: skill.customPhotoData,
                            size: 48
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Level \(skill.depth)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(skill.name)
                        }
                    }
                }
            }
            .onMove(perform: moveSkills)
        }
        .listStyle(.grouped)
        .navigationTitle(family.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { addVariantPresented = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $addVariantPresented) {
            AddVariantSheet(
                family: family,
                currentSkill: nil,
                defaultInsertBefore: nil,
                onSave: { name, instructions, photos, insertBefore in
                    addVariant(name: name, instructions: instructions,
                               photos: photos, insertBefore: insertBefore)
                }
            )
        }
    }

    private func moveSkills(from: IndexSet, to: Int) {
        var ordered = Array(skills)
        ordered.move(fromOffsets: from, toOffset: to)
        for (i, skill) in ordered.enumerated() {
            skill.depth = Int16(i + 1)
        }
        services.coreData.save()
    }

    private func addVariant(name: String, instructions: String, photos: [Data], insertBefore: CDAbsSkill?) {
        let moc = services.coreData.moc
        let ordered = Array(skills)
        let targetDepth: Int16
        if let anchor = insertBefore {
            targetDepth = anchor.depth
            for skill in ordered where skill.depth >= targetDepth {
                if skill.bundleDepth == 0 && !skill.hideBundleImages {
                    skill.bundleDepth = skill.depth
                }
                skill.depth += 1
            }
        } else {
            targetDepth = (ordered.map(\.depth).max() ?? 0) + 1
        }
        let skill = CDAbsSkill(context: moc)
        skill.name = name
        skill.depth = targetDepth
        skill.instructions = instructions
        skill.customPhotos = photos
        skill.hideBundleImages = true
        skill.series = family.series
        skill.family = family.name
        skill.url = URL(string: "about:blank")!
        skill.skillFamily = family
        services.coreData.save()
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SkillFamilyDetailView(family: PreviewSupport.sampleFamily)
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
