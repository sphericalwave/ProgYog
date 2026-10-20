//
//  AddVariantSheet.swift
//  Groundwerk
//

import SwiftUI
import SwKeyboard
import SwMediaKit

struct AddVariantSheet: View {
    let family: CDSkillFamily
    let currentSkill: CDAbsSkill?
    let defaultInsertBefore: CDAbsSkill?
    let onSave: (_ name: String, _ instructions: String, _ photos: [Data], _ insertBefore: CDAbsSkill?, _ tracksWeight: Bool, _ weightStepLbs: Double) -> Void

    @State private var name = ""
    @State private var instructions = ""
    @State private var photos: [Data] = []
    @State private var insertion: Insertion = .atEnd
    @State private var tracksWeight = false
    @State private var weightStepLbs: Double?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name
        case instructions
        case weightStep
    }

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
            ScrollViewReader { scrollProxy in
            Form {
                Section("Skill") {
                    TextField("Name", text: $name)
                        .focused($focusedField, equals: .name)
                        .id(Field.name)
                        .scrollsIntoView(id: Field.name, isFocused: focusedField == .name, proxy: scrollProxy)
                    TextField("Instructions (optional)", text: $instructions, axis: .vertical)
                        .lineLimit(2...5)
                        .focused($focusedField, equals: .instructions)
                        .id(Field.instructions)
                        .scrollsIntoView(id: Field.instructions, isFocused: focusedField == .instructions, proxy: scrollProxy)
                }

                Section("Equipment") {
                    Toggle("Tracks Weight", isOn: $tracksWeight)
                    if tracksWeight {
                        HStack {
                            Text("Step")
                            Spacer()
                            NumericTextField("lbs", value: $weightStepLbs)
                                .focused($focusedField, equals: .weightStep)
                                .id(Field.weightStep)
                                .scrollsIntoView(id: Field.weightStep, isFocused: focusedField == .weightStep, proxy: scrollProxy)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                        }
                    }
                }

                Section("Photos") {
                    // 0 = no limit; each pick is appended, the x on a thumbnail removes it.
                    MediaSourceButton(selectionLimit: 0, onImage: { photos.append($0) }) {
                        Label(photos.isEmpty ? "Add Photos" : "Add Photos (\(photos.count))",
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
                        onSave(name, instructions, photos, insertion.insertBefore, tracksWeight, weightStepLbs ?? 0)
                        dismiss()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                insertion = defaultInsertBefore.map { .before($0) } ?? .atEnd
            }
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
        onSave: { _, _, _, _, _, _ in }
    )
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}
#endif
