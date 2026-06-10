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
        let bundleNames = skill.posterAssetNames
        let customImgs = skill.customPhotos.compactMap { UIImage(data: $0) }

        if !bundleNames.isEmpty {
            animatedBundleView(names: bundleNames)
        } else if !customImgs.isEmpty {
            animatedCustomView(images: customImgs)
        }
    }

    @ViewBuilder
    private func animatedBundleView(names: [String]) -> some View {
        Group {
            if paused {
                Image(names[min(pausedFrame, names.count - 1)])
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: maxHeight)
            } else {
                TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                    let idx = Int(tl.date.timeIntervalSinceReferenceDate) % names.count
                    Image(names[idx])
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: maxHeight)
                        .onChange(of: idx) { _, new in pausedFrame = new }
                }
            }
        }
        .modifier(PosterFrame(maxHeight: maxHeight, cornerRadius: cornerRadius,
                              colorScheme: colorScheme, showPause: true,
                              paused: $paused))
    }

    @ViewBuilder
    private func animatedCustomView(images: [UIImage]) -> some View {
        Group {
            if paused || images.count == 1 {
                Image(uiImage: images[min(pausedFrame, images.count - 1)])
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: maxHeight)
            } else {
                TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                    let idx = Int(tl.date.timeIntervalSinceReferenceDate) % images.count
                    Image(uiImage: images[idx])
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: maxHeight)
                        .onChange(of: idx) { _, new in pausedFrame = new }
                }
            }
        }
        .modifier(PosterFrame(maxHeight: maxHeight, cornerRadius: cornerRadius,
                              colorScheme: colorScheme, showPause: images.count > 1,
                              paused: $paused))
    }
}

private struct PosterFrame: ViewModifier {
    let maxHeight: CGFloat
    let cornerRadius: CGFloat
    let colorScheme: ColorScheme
    let showPause: Bool
    @Binding var paused: Bool

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(alignment: .topTrailing) {
                if showPause {
                    Button { paused.toggle() } label: {
                        Image(systemName: paused ? "play.fill" : "pause.fill")
                            .font(.caption).padding(6)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                }
            }
    }
}
