import SwiftUI

struct PostureRecordingsView: View {
    @ObservedObject var store: PostureStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.snapshots) { snap in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(snap.postureClass).font(.headline)
                            Spacer()
                            Text(snap.date, format: .dateTime.month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 20) {
                            metric("Spine", snap.spineLabel)
                            metric("Hips", snap.hipLabel)
                            metric("Shoulders", snap.shoulderLabel)
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: store.delete)
            }
            .navigationTitle("Posture Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !store.snapshots.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All", role: .destructive) { confirmClear = true }
                    }
                }
            }
            .overlay {
                if store.snapshots.isEmpty {
                    ContentUnavailableView(
                        "No Recordings",
                        systemImage: "person.fill.viewfinder",
                        description: Text("Tap the record button in Posture Check to save a reading.")
                    )
                }
            }
            .confirmationDialog("Clear all posture recordings?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) { store.clearAll() }
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).foregroundStyle(.secondary)
            Text(value).fontWeight(.medium)
        }
    }
}
