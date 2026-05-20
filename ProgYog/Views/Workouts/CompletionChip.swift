//
//  CompletionChip.swift
//  ProgYog
//
//  Small capsule that displays a 0–100 % completion score, color-coded.
//  Used in WorkoutListView, WorkoutDetailView, WorkoutSummaryView.
//

import SwiftUI

struct CompletionChip: View {
    /// 0...100, or nil when there is no qualifying data (renders "—").
    let percent: Double?
    /// Optional sub-label, e.g. "last" or "best".
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.caption2.weight(.semibold).monospacedDigit())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(tint.opacity(0.18)))
                .foregroundStyle(tint)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var label: String {
        guard let p = percent else { return "—" }
        return "\(Int(p.rounded()))%"
    }

    private var tint: Color {
        guard let p = percent else { return .secondary }
        switch p {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        CompletionChip(percent: nil, caption: "last")
        CompletionChip(percent: 12, caption: "last")
        CompletionChip(percent: 55, caption: "best")
        CompletionChip(percent: 92, caption: "best")
    }
    .padding()
}
#endif
