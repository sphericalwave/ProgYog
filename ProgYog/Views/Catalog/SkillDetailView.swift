//
//  SkillDetailView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillDetailView: View {
    @ObservedObject var skill: CDAbsSkill

    @Environment(\.managedObjectContext) private var moc
    @FetchRequest private var logs: FetchedResults<SetLog>
    @State private var editingInstructions = false

    init(skill: CDAbsSkill) {
        self.skill = skill
        _logs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: true)],
            predicate: NSPredicate(format: "absSkill == %@", skill)
        )
    }

    var body: some View {
        List {
            if !skill.posterAssetNames.isEmpty {
                Section {
                    SkillPosterGallery(names: skill.posterAssetNames)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section {
                LabeledContent("Family", value: skill.family)
                LabeledContent("Series", value: skill.series)
                LabeledContent("Level", value: "\(skill.depth)")
                LabeledContent("Symmetrical", value: skill.symetrical ? "Yes" : "No")
            }

            Section {
                if skill.instructions.isEmpty {
                    Text("No instructions yet.")
                        .foregroundStyle(.tertiary)
                } else {
                    Text(skill.instructions)
                }
            } header: {
                HStack {
                    Text("Instructions")
                    Spacer()
                    Button { editingInstructions = true } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)
                }
            }

            if logs.isEmpty {
                Section("Trend") {
                    Text("No sets logged yet for this skill.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Trend") {
                    SkillTrendChart(logs: Array(logs))
                }

                Section("Recent Sets") {
                    ForEach(logs.suffix(10).reversed(), id: \.id) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.loggedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.bold())
                            HStack(spacing: 4) {
                                Text("reps \(log.reps) · ROM \(log.rom)% · RPT \(log.rpt) · RPE \(log.rpe) · RPD \(log.rpd) ·")
                                    .foregroundStyle(.secondary)
                                Text(log.decisionValue.label)
                                    .foregroundStyle(log.decisionValue.color)
                                    .bold()
                            }
                            .font(.caption)
                            if let notes = log.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !skill.posterAssetNames.isEmpty {
                Section("Images") {
                    ForEach(skill.posterAssetNames, id: \.self) { name in
                        Image(name)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(skill.name)
        .sheet(isPresented: $editingInstructions) {
            InstructionsEditSheet(initialText: skill.instructions) { newText in
                skill.instructions = newText
                try? moc.save()
            }
        }
    }
}

struct InstructionsEditSheet: View {
    let initialText: String
    let onSave: (String) -> Void
    @State private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $draft)
                .padding(.horizontal, 4)
                .navigationTitle("Instructions")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { onSave(draft); dismiss() }.bold()
                    }
                }
        }
        .onAppear { draft = initialText }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SkillDetailView(skill: PreviewSupport.sampleSkill)
    }
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
