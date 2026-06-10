//
//  SkillDetailView.swift
//  ProgYog
//

import SwiftUI
import CoreData
import PhotosUI

struct SkillDetailView: View {
    @ObservedObject var skill: CDAbsSkill

    @Environment(\.managedObjectContext) private var moc
    @FetchRequest private var logs: FetchedResults<SetLog>
    @State private var editingInstructions = false
    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var selectedItems: [PhotosPickerItem] = []

    init(skill: CDAbsSkill) {
        self.skill = skill
        _logs = FetchRequest<SetLog>(
            sortDescriptors: [NSSortDescriptor(key: "loggedAt", ascending: true)],
            predicate: NSPredicate(format: "absSkill == %@", skill)
        )
    }

    private var hasAnyImage: Bool {
        !skill.posterAssetNames.isEmpty || !skill.customPhotos.isEmpty
    }

    var body: some View {
        List {
            Section {
                if hasAnyImage {
                    SkillAnimatedPoster(skill: skill)
                        .listRowInsets(EdgeInsets())
                } else {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 0, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Add Photos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }
            }

            if hasAnyImage && skill.hideBundleImages {
                Section {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 0, matching: .images) {
                        Label("Add / Replace Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    let photos = skill.customPhotos
                    if !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photos.indices, id: \.self) { i in
                                    if let img = UIImage(data: photos[i]) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 72, height: 72)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            Button {
                                                var updated = skill.customPhotos
                                                updated.remove(at: i)
                                                skill.customPhotos = updated
                                                try? moc.save()
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white, .black.opacity(0.6))
                                                    .font(.caption)
                                                    .padding(3)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Photos")
                }
            }

            Section {
                LabeledContent("Name") {
                    if editingName {
                        TextField("Name", text: $nameDraft, onCommit: {
                            skill.name = nameDraft
                            try? moc.save()
                            editingName = false
                        })
                        .multilineTextAlignment(.trailing)
                    } else {
                        Text(skill.name)
                            .onTapGesture {
                                nameDraft = skill.name
                                editingName = true
                            }
                    }
                }
                LabeledContent("Family", value: skill.family)
                LabeledContent("Series", value: skill.series)
                LabeledContent("Level", value: "\(skill.depth)")
                Toggle("Symmetrical", isOn: Binding(
                    get: { skill.symetrical },
                    set: { skill.symetrical = $0; try? moc.save() }
                ))
                .tint(.accentColor)
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
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editingInstructions) {
            InstructionsEditSheet(initialText: skill.instructions) { newText in
                skill.instructions = newText
                try? moc.save()
            }
        }
        .onChange(of: selectedItems) { _, items in
            Task {
                var loaded: [Data] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loaded.append(data)
                    }
                }
                if !loaded.isEmpty {
                    skill.customPhotos = skill.customPhotos + loaded
                    try? moc.save()
                    selectedItems = []
                }
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
