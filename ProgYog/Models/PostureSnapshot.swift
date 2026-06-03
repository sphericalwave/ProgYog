import Foundation

// Captures exactly what the Vision HUD shows at a point in time.
struct PostureSnapshot: Codable, Identifiable {
    let id: UUID
    let date: Date
    let postureClass: String
    let spineLabel: String
    let hipLabel: String
    let shoulderLabel: String
}

extension PostureSnapshot {
    init(from report: PostureReport) {
        id = UUID()
        date = Date()
        postureClass = report.postureClass.rawValue
        spineLabel = report.spineLabel
        hipLabel = report.hipLabel
        shoulderLabel = report.shoulderLabel
    }
}
