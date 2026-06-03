import SwiftUI

struct PostureHUDView: View {
    let report: PostureReport?

    var body: some View {
        Group {
            if let report {
                VStack(spacing: 6) {
                    Text(report.postureClass.rawValue)
                        .font(.headline)
                    HStack(spacing: 20) {
                        metric("Spine", report.spineLabel)
                        metric("Hips", report.hipLabel)
                        metric("Shoulders", report.shoulderLabel)
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).foregroundStyle(.secondary)
            Text(value).fontWeight(.medium)
        }
    }
}
