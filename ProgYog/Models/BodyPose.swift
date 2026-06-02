import Vision
import CoreGraphics

struct BodyJoint {
    let position: CGPoint  // Vision normalized coords: origin bottom-left, range [0, 1]
    let confidence: Float
}

struct BodyPose {
    let joints: [VNHumanBodyPoseObservation.JointName: BodyJoint]

    subscript(_ name: VNHumanBodyPoseObservation.JointName) -> BodyJoint? {
        joints[name]
    }

    // 18 limb pairs that define the stick-figure skeleton
    static let limbConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        // Head
        (.neck, .nose),
        (.nose, .leftEye),
        (.nose, .rightEye),
        (.leftEye, .leftEar),
        (.rightEye, .rightEar),
        // Spine
        (.neck, .root),
        // Left arm
        (.neck, .leftShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        // Right arm
        (.neck, .rightShoulder),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        // Left leg
        (.root, .leftHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        // Right leg
        (.root, .rightHip),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
    ]

    static func from(_ observation: VNHumanBodyPoseObservation) -> BodyPose? {
        guard let recognized = try? observation.recognizedPoints(.all) else { return nil }
        let joints = recognized.reduce(into: [VNHumanBodyPoseObservation.JointName: BodyJoint]()) { map, pair in
            map[pair.key] = BodyJoint(position: pair.value.location, confidence: pair.value.confidence)
        }
        return BodyPose(joints: joints)
    }
}
