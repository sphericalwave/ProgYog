//
//  SkillPickerSheet.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillPickerSheet: View {
    let workoutCode: String
    let onPick: (CDAbsSkill) -> Void

    @FetchRequest private var families: FetchedResults<CDSkillFamily>
    @Environment(\.dismiss) private var dismiss

    init(workoutCode: String, onPick: @escaping (CDAbsSkill) -> Void) {
        self.workoutCode = workoutCode
        self.onPick = onPick
        _families = FetchRequest<CDSkillFamily>(
            sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)],
            predicate: NSPredicate(format: "series == %@", workoutCode)
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(families, id: \.self) { family in
                    Section("\(family.order). \(family.name)") {
                        ForEach(orderedSkills(in: family), id: \.self) { skill in
                            Button {
                                onPick(skill)
                            } label: {
                                HStack {
                                    Text("Level \(skill.depth)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                    Text(skill.name)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Add Set")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func orderedSkills(in family: CDSkillFamily) -> [CDAbsSkill] {
        let set = (family.absSkills as? Set<CDAbsSkill>) ?? []
        return set.sorted { $0.depth < $1.depth }
    }
}

#if DEBUG
#Preview {
    SkillPickerSheet(workoutCode: "A") { _ in }
        .environmentObject(PreviewSupport.services)
        .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
