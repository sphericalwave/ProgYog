import Foundation

@MainActor
final class PostureStore: ObservableObject {
    private static let key = "postureSnapshots"
    @Published private(set) var snapshots: [PostureSnapshot] = []

    init() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.key),
            let decoded = try? JSONDecoder().decode([PostureSnapshot].self, from: data)
        else { return }
        snapshots = decoded
    }

    func record(_ report: PostureReport) {
        snapshots.insert(PostureSnapshot(from: report), at: 0)
        if snapshots.count > 100 { snapshots = Array(snapshots.prefix(100)) }
        persist()
    }

    func delete(at offsets: IndexSet) {
        snapshots.remove(atOffsets: offsets)
        persist()
    }

    func clearAll() {
        snapshots.removeAll()
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(snapshots), forKey: Self.key)
    }
}
