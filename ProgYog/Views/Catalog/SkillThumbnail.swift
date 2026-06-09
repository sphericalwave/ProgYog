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
    var size: CGFloat = 48

    var body: some View {
        Group {
            let names = assetNames.isEmpty ? (assetName.map { [$0] } ?? []) : assetNames
            if names.count > 1 {
                TimelineView(.periodic(from: .now, by: 0.333)) { tl in
                    let idx = Int(tl.date.timeIntervalSinceReferenceDate) % names.count
                    Image(names[idx])
                        .resizable()
                        .scaledToFill()
                }
            } else if let n = names.first {
                Image(n)
                    .resizable()
                    .scaledToFill()
            } else if let data = photoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "figure.yoga")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
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
