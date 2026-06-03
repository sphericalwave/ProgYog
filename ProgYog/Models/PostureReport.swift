import CoreGraphics

struct PostureReport {
    enum PostureClass: String {
        case standing = "Standing"
        case seated = "Seated"
        case inverted = "Inverted"
        case supine = "Supine"
        case unknown = "Unknown"
    }

    let postureClass: PostureClass
    let spineAngle: Double    // degrees: 0 = vertical, + = lean right, – = lean left
    let hipTilt: Double?      // degrees: + = right hip higher, – = left hip higher
    let shoulderTilt: Double? // degrees: + = right shoulder higher, – = left shoulder higher

    var spineLabel: String {
        let mag = abs(spineAngle)
        if mag < 3 { return "Vertical" }
        return String(format: "%.0f° %@", mag, spineAngle > 0 ? "R" : "L")
    }

    var hipLabel: String {
        guard let t = hipTilt else { return "—" }
        let mag = abs(t)
        if mag < 2 { return "Level" }
        return String(format: "%.0f° %@ high", mag, t > 0 ? "R" : "L")
    }

    var shoulderLabel: String {
        guard let t = shoulderTilt else { return "—" }
        let mag = abs(t)
        if mag < 2 { return "Level" }
        return String(format: "%.0f° %@ high", mag, t > 0 ? "R" : "L")
    }
}
