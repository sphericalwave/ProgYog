//
//  UndoToast.swift
//  Groundwerk
//
//  "Restored …" banner shown after an undo (shake on iOS, ⌥⌘Z on macOS).
//

import SwiftUI

struct UndoToast: View {
    @EnvironmentObject private var services: AppServices

    var body: some View {
        Group {
            if let desc = services.undo.lastRestoredDescription {
                Label("Restored \(desc)", systemImage: "arrow.uturn.backward.circle.fill")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.2)))
                    .padding(.top, 6)
                    .shadow(radius: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(desc) // restarts auto-clear when a new entry arrives
            }
        }
        .animation(.easeInOut(duration: 0.25),
                   value: services.undo.lastRestoredDescription)
        .onChange(of: services.undo.lastRestoredDescription) { _, new in
            guard new != nil else { return }
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if services.undo.lastRestoredDescription == new {
                    services.undo.lastRestoredDescription = nil
                }
            }
        }
    }
}
