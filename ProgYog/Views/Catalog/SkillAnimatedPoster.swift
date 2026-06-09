//
//  SkillAnimatedPoster.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct SkillAnimatedPoster: View {
    let skill: CDAbsSkill
    var maxHeight: CGFloat = 220
    var cornerRadius: CGFloat = 12

    @State private var paused = false
    @State private var pausedFrame = 0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let names = skill.posterAssetNames
        if !names.isEmpty {
            Group {
                if paused {
                    Image(names[pausedFrame])
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: maxHeight)
                } else {
                    TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                        let idx = Int(tl.date.timeIntervalSinceReferenceDate) % names.count
                        Image(names[idx])
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: maxHeight)
                            .onChange(of: idx) { _, new in pausedFrame = new }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(alignment: .topTrailing) {
                Button { paused.toggle() } label: {
                    Image(systemName: paused ? "play.fill" : "pause.fill")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }
        } else if let data = skill.customPhotoData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
