//
//  SkillPoster.swift
//  Groundwerk
//
//  App-side adapter: maps a CoreData CDAbsSkill onto SwMediaKit's plain-data
//  AnimatedPoster. Keeps the CoreData→[String]/[Data] mapping in one place so
//  call sites stay clean.
//

import SwiftUI
import SwMediaKit

struct SkillPoster: View {
    let skill: CDAbsSkill
    var maxHeight: CGFloat = 220
    var cornerRadius: CGFloat = 12

    var body: some View {
        AnimatedPoster(bundleNames: skill.posterAssetNames,
                       photos: skill.customPhotos,
                       maxHeight: maxHeight, cornerRadius: cornerRadius)
    }
}
