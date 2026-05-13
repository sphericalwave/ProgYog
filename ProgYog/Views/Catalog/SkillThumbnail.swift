//
//  SkillThumbnail.swift
//  ProgYog
//

import SwiftUI

struct SkillThumbnail: View {
    let assetName: String?
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let n = assetName {
                Image(n)
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
