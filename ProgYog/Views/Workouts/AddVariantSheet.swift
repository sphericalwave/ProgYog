//
//  AddVariantSheet.swift
//  ProgYog
//

import SwiftUI
import SwKeyboard
import PhotosUI

struct AddVariantSheet: View {
    let family: CDSkillFamily
    let currentSkill: CDAbsSkill?
    let defaultInsertBefore: CDAbsSkill?
    let onSave: (_ name: String, _ instructions: String, _ photos: [Data], _ insertBefore: CDAbsSkill?) -> Void

    @State private var name = ""
    @State private var instructions = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photos: [Data] = []
    @State private var insertion: Insertion = .atEnd
    @Environment(\.dismiss) private var dismiss

    enum Insertion: Equatable {
        case before(CDAbsSkill)
        case atEnd

        var insertBefore: CDAbsSkill? {
            if case .before(let skill) = self { return skill }
            return nil
        }

        static func == (lhs: Insertion, rhs: Insertion) -> Bool {
            switch (lhs, rhs) {
            case (.atEnd, .atEnd): return true
            case (.before(let a), .before(let b)): return a.objectID == b.objectID
            default: return false
            }
        }
    }

    private var orderedSkills: [CDAbsSkill] { family.orderedAbsSkills }

    var body: some View {
        NavigationStack {
            Form {
                Section("Skill") {
                    TextField("Name", text: $name)
                    TextField("Instructions (optional)", text: $instructions, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Photos") {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 0, matching: .images) {
                        Label(photos.isEmpty ? "Choose Photos" : "Change Photos (\(photos.count))",
                              systemImage: "photo.on.rectangle.angled")
                    }
                    if !photos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(photos.indices, id: \.self) { i in
                                    if let img = PlatformImage.from(data: photos[i]) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(platformImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            Button {
                                                photos.remove(at: i)
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
                }

                Section("Insert position") {
                    ForEach(orderedSkills, id: \.objectID) { skill in
                        insertionRow(for: .before(skill))
                        skillRow(skill)
                    }
                    insertionRow(for: .atEnd)
                }
            }
            .navigationTitle("Add Variant")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .doneKeyboardToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Save") {
                        onSave(name, instructions, photos, insertion.insertBefore)
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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
                    photos = loaded
                }
            }
            .onAppear {
                insertion = defaultInsertBefore.map { .before($0) } ?? .atEnd
            }
        }
    }

    @ViewBuilder
    private func insertionRow(for point: Insertion) -> some View {
        let isSelected = insertion == point
        Button {
            insertion = point
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text("Insert here")
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func skillRow(_ skill: CDAbsSkill) -> some View {
        HStack {
            Text(skill.name)
                .font(.callout)
            Spacer()
            if skill.objectID == currentSkill?.objectID {
                Text("current")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(.systemFill)))
            }
            Text("L\(skill.depth)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

#if DEBUG
#Preview {
    AddVariantSheet(
        family: PreviewSupport.sampleFamily,
        currentSkill: PreviewSupport.sampleSkill,
        defaultInsertBefore: PreviewSupport.sampleSkill,
        onSave: { _, _, _, _ in }
    )
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
