//
//  SkillThumbnail.swift
//  ProgYog
//

import SwiftUI
import UIKit

struct SkillThumbnail: View {
    let assetName: String?
    var assetNames: [String] = []
    var photoData: Data? = nil
    var photos: [Data] = []
    var size: CGFloat = 48

    @State private var cachedPhotos: [UIImage] = []
    @State private var cachedPhoto: UIImage? = nil

    private var bundleNames: [String] {
        assetNames.isEmpty ? (assetName.map { [$0] } ?? []) : assetNames
    }

    var body: some View {
        Group {
            if bundleNames.count > 1 {
                TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                    let idx = Int(tl.date.timeIntervalSinceReferenceDate) % bundleNames.count
                    Image(bundleNames[idx]).resizable().scaledToFill()
                }
            } else if let n = bundleNames.first {
                Image(n).resizable().scaledToFill()
            } else if cachedPhotos.count > 1 {
                TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                    let idx = Int(tl.date.timeIntervalSinceReferenceDate) % cachedPhotos.count
                    Image(uiImage: cachedPhotos[idx]).resizable().scaledToFill()
                }
            } else if let img = cachedPhotos.first {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let img = cachedPhoto {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Image(systemName: "figure.yoga")
                    .resizable().scaledToFit()
                    .padding(8)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .task(id: photos.count) {
            guard bundleNames.isEmpty else { return }
            cachedPhotos = photos.compactMap { UIImage(data: $0) }
        }
        .task(id: photoData?.count) {
            guard bundleNames.isEmpty, photos.isEmpty else { return }
            cachedPhoto = photoData.flatMap { UIImage(data: $0) }
        }
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        SkillThumbnail(assetName: PreviewSupport.sampleSkill.posterAssetName)
        SkillThumbnail(assetName: nil)
    }
    .padding()
}
#endif
