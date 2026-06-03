import SwiftUI

struct PostureCameraView: View {
    @StateObject private var detector = PoseDetectionService()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented

    private var report: PostureReport? {
        detector.pose.flatMap(PostureAnalyzer.analyze)
    }

    var body: some View {
        ZStack {
            CameraPreviewView(captureSession: detector.captureSession)
                .ignoresSafeArea()

            PoseOverlayCanvas(pose: detector.pose)

            VStack {
                Spacer()
                PostureHUDView(report: report)
                    .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea()
        .navigationTitle("Posture Check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    detector.flip()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                }
                .tint(.white)
            }
            if isPresented {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(.white)
                }
            }
        }
        .task { detector.start() }
        .onDisappear { detector.stop() }
    }
}
