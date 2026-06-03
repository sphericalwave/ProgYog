import SwiftUI

struct PostureCameraView: View {
    @StateObject private var detector = PoseDetectionService()
    @StateObject private var store = PostureStore()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var recordingsPresented = false
    @State private var didRecord = false

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

            // Brief "Saved" confirmation
            if didRecord {
                VStack {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.green.opacity(0.85), in: Capsule())
                        .padding(.top, 80)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .navigationTitle("Posture Check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { detector.flip() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                }
                .tint(.white)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    // Record current reading
                    Button {
                        guard let r = report else { return }
                        store.record(r)
                        withAnimation { didRecord = true }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            withAnimation { didRecord = false }
                        }
                    } label: {
                        Image(systemName: "record.circle")
                    }
                    .tint(report != nil ? .red : .white.opacity(0.4))
                    .disabled(report == nil)

                    // History
                    Button { recordingsPresented = true } label: {
                        Image(systemName: "list.bullet.clipboard")
                    }
                    .tint(.white)
                    .badge(store.snapshots.count)

                    if isPresented {
                        Button("Done") { dismiss() }
                            .tint(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $recordingsPresented) {
            PostureRecordingsView(store: store)
        }
        .task { detector.start() }
        .onDisappear { detector.stop() }
    }
}
