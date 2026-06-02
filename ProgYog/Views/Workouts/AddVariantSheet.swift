//
//  AddVariantSheet.swift
//  ProgYog
//

import SwiftUI
import PhotosUI

struct AddVariantSheet: View {
    let family: CDSkillFamily
    let currentSkill: CDAbsSkill?
    let defaultInsertBefore: CDAbsSkill?
    let onSave: (_ name: String, _ instructions: String, _ photoData: Data?, _ insertBefore: CDAbsSkill?) -> Void

    @State private var name = ""
    @State private var instructions = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
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

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                    }
                    if let data = photoData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, instructions, photoData, insertion.insertBefore)
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task { photoData = try? await item?.loadTransferable(type: Data.self) }
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
