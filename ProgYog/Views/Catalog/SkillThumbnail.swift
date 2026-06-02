//
//  SkillThumbnail.swift
//  ProgYog
//

import SwiftUI
import UIKit

struct SkillThumbnail: View {
    let assetName: String?
    var photoData: Data? = nil
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let n = assetName {
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
