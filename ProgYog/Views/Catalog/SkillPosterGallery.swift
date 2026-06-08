//
//  SkillPosterGallery.swift
//  ProgYog
//

import SwiftUI

struct SkillPosterGallery: View {
    let names: [String]
    var contentMode: ContentMode = .fit

    var body: some View {
        if names.isEmpty {
            EmptyView()
        } else {
            TabView {
                ForEach(names, id: \.self) { n in
                    Image(n)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: names.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .aspectRatio(4.0 / 3.0, contentMode: contentMode)
        }
    }
}

#if DEBUG
#Preview {
    SkillPosterGallery(names: PreviewSupport.sampleSkill.posterAssetNames)
        .padding()
}
#endif
