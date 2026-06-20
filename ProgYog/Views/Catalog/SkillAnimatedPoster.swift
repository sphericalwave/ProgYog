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
    @State private var pausedDate: Date = .now
    @State private var cachedCustomPhotos: [PlatformImage] = []
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let bundleNames = skill.posterAssetNames

        Group {
            if !bundleNames.isEmpty {
                animatedBundleView(names: bundleNames)
            } else if !cachedCustomPhotos.isEmpty {
                animatedCustomView(images: cachedCustomPhotos)
            } else {
                Color.clear
            }
        }
        .task(id: skill.objectID) {
            let photoData = skill.customPhotos
            cachedCustomPhotos = photoData.compactMap { PlatformImage.from(data: $0) }
        }
    }

    @ViewBuilder
    private func animatedBundleView(names: [String]) -> some View {
        Group {
            if paused {
                let idx = Int(pausedDate.timeIntervalSinceReferenceDate) % names.count
                Image(names[idx])
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: maxHeight)
            } else {
                TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                    let idx = Int(tl.date.timeIntervalSinceReferenceDate) % names.count
                    Image(names[idx])
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: maxHeight)
                }
            }
        }
        .modifier(PosterFrame(maxHeight: maxHeight, cornerRadius: cornerRadius,
                              colorScheme: colorScheme, showPause: true,
                              paused: $paused, onPause: { pausedDate = .now }))
    }

    @ViewBuilder
    private func animatedCustomView(images: [PlatformImage]) -> some View {
        Group {
            if paused || images.count == 1 {
                let idx = Int(pausedDate.timeIntervalSinceReferenceDate) % images.count
                Image(platformImage: images[idx])
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: maxHeight)
            } else {
                TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                    let idx = Int(tl.date.timeIntervalSinceReferenceDate) % images.count
                    Image(platformImage: images[idx])
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: maxHeight)
                }
            }
        }
        .modifier(PosterFrame(maxHeight: maxHeight, cornerRadius: cornerRadius,
                              colorScheme: colorScheme, showPause: images.count > 1,
                              paused: $paused, onPause: { pausedDate = .now }))
    }
}

private struct PosterFrame: ViewModifier {
    let maxHeight: CGFloat
    let cornerRadius: CGFloat
    let colorScheme: ColorScheme
    let showPause: Bool
    @Binding var paused: Bool
    var onPause: () -> Void = {}

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(alignment: .topTrailing) {
                if showPause {
                    Button { onPause(); paused.toggle() } label: {
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
