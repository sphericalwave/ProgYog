import SwiftUI
import Vision

struct PoseOverlayCanvas: View {
    let pose: BodyPose?

    var body: some View {
        Canvas { context, size in
            guard let pose else { return }

            // Limbs (levers) drawn first so joints (frames) render on top
            for (a, b) in BodyPose.limbConnections {
                guard let jA = pose[a], let jB = pose[b],
                      jA.confidence >= 0.3, jB.confidence >= 0.3 else { continue }
                let minConf = min(jA.confidence, jB.confidence)
                var path = Path()
                path.move(to: screenPoint(jA.position, in: size))
                path.addLine(to: screenPoint(jB.position, in: size))
                context.stroke(path, with: .color(overlayColor(minConf)), lineWidth: 3)
            }

            // Joints (frames)
            for (_, joint) in pose.joints {
                guard joint.confidence >= 0.3 else { continue }
                let center = screenPoint(joint.position, in: size)
                let radius = CGFloat(5 + 4 * joint.confidence)
                let rect = CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(overlayColor(joint.confidence)))
            }
        }
        .allowsHitTesting(false)
    }

    // Vision: bottom-left origin, [0,1]. Rotation + mirror baked into the capture connection.
    private func screenPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
    }

    private func overlayColor(_ confidence: Float) -> Color {
        if confidence >= 0.7 { return .green }
        if confidence >= 0.5 { return .yellow }
        return .orange
    }
}
