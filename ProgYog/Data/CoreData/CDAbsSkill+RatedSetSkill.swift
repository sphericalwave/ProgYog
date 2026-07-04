//
//  CDAbsSkill+RatedSetSkill.swift
//  ProgYog
//
//  progYog's CoreData skill can't conform to SetLogKit's RatedSetSkill
//  directly — its `depth` is Int16, but the protocol requires `depth: Int`,
//  and you can't redeclare a stored property via extension. A small value
//  adapter bridges the Int16↔Int gap so CDAbsSkill can drive RatedSetForm.
//

import Foundation
import SetLogKit

/// Value snapshot of a CDAbsSkill in the shape RatedSetForm needs.
struct RatedSkillInfo: RatedSetSkill {
    let displayName: String
    let familyName: String?
    let depth: Int
    let maxDepth: Int
    let priorSets: [PriorSet]
    let defaultSliceCount: Int

    init(_ skill: CDAbsSkill) {
        displayName = skill.name
        familyName = skill.skillFamily?.name
        depth = Int(skill.depth)
        maxDepth = Int(skill.skillFamily?.maxDepth ?? skill.depth)
        defaultSliceCount = Int(skill.sliceCount)
        let logs = (skill.setLogs as? Set<SetLog>) ?? []
        priorSets = logs.map {
            PriorSet(reps: Int($0.reps), rpt: Int($0.rpt), rpe: Int($0.rpe),
                     rpd: Int($0.rpd), notes: $0.notes, loggedAt: $0.loggedAt)
        }
    }
}
