import SwiftUI

struct PostureCameraView: View {
    @StateObject private var detector = PoseDetectionService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CameraPreviewView(captureSession: detector.captureSession)
                .ignoresSafeArea()

            PoseOverlayCanvas(pose: detector.pose)

            // Status overlay — shows permission errors, Vision errors, or frame count.
            // Remove once skeleton is reliably working.
            VStack {
                Spacer()
                Text(detector.status)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.5), in: Capsule())
                    .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea()
        .navigationTitle("Posture Check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .tint(.white)
            }
        }
        .task { detector.start() }
        .onDisappear { detector.stop() }
    }
}
