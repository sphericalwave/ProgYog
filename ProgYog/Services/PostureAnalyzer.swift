import Vision
import CoreGraphics

enum PostureAnalyzer {
    static func analyze(_ pose: BodyPose) -> PostureReport? {
        guard let neck = pose[.neck], neck.confidence > 0.3 else { return nil }

        let root = pose[.root].flatMap { $0.confidence > 0.3 ? $0 : nil }

        let spineAngle = root.map {
            tiltDeg(dx: neck.position.x - $0.position.x, dy: neck.position.y - $0.position.y)
        } ?? 0.0

        let postureClass = root.map {
            classify(pose: pose, neckY: neck.position.y, rootY: $0.position.y)
        } ?? .unknown

        return PostureReport(
            postureClass: postureClass,
            spineAngle: spineAngle,
            hipTilt: lateralTilt(pose[.leftHip], pose[.rightHip]),
            shoulderTilt: lateralTilt(pose[.leftShoulder], pose[.rightShoulder])
        )
    }

    // Angle of vector (dx, dy) from vertical. + = right lean, – = left lean.
    // Vision coords: y increases upward, so vertical = +dy direction.
    private static func tiltDeg(dx: CGFloat, dy: CGFloat) -> Double {
        atan2(dx, dy) * 180 / .pi
    }

    // Angle of left→right joint line from horizontal. + = right joint higher, – = left higher.
    private static func lateralTilt(_ left: BodyJoint?, _ right: BodyJoint?) -> Double? {
        guard let l = left, let r = right, l.confidence > 0.3, r.confidence > 0.3 else { return nil }
        return atan2(r.position.y - l.position.y, r.position.x - l.position.x) * 180 / Double.pi
    }

    private static func classify(
        pose: BodyPose, neckY: CGFloat, rootY: CGFloat
    ) -> PostureReport.PostureClass {
        if rootY > neckY + 0.1 { return .inverted }

        let ys = pose.joints.values.filter { $0.confidence > 0.3 }.map(\.position.y)
        if let lo = ys.min(), let hi = ys.max(), hi - lo < 0.25 { return .supine }

        let anklesLow = [pose[.leftAnkle], pose[.rightAnkle]]
            .compactMap { $0 }
            .contains { $0.confidence > 0.3 && $0.position.y < 0.3 }

        return anklesLow ? .standing : .seated
    }
}
