//
//  SetLogSheet.swift
//  ProgYog
//
//  Thin wrapper over SetLogKit's shared RatedSetForm. progYog logs bodyweight
//  skills, so the form is used with NoEquipment. Keeps progYog's `Entry` type
//  and init signature so call sites are unchanged; the CoreData skill is
//  snapshotted into a RatedSkillInfo for the form and reused directly for the
//  animated-poster header.
//

import SwiftUI
import SetLogKit
import CoreData

struct SetLogSheet: View {
    let skill: CDAbsSkill
    let suggestion: ProgressionDecision
    let editing: SetLog?
    let currentSession: Session?
    let liveHRStats: (min: Int, max: Int, avg: Int)?
    let isFinalRound: Bool
    let initialIsometric: Bool
    let onSave: (_ entry: Entry) -> Void
    let onCancel: (() -> Void)?

    struct Entry {
        let reps: Int
        let rpt: Int
        let rpe: Int
        let rpd: Int
        let notes: String
        let decision: ProgressionDecision
        let isometric: Bool
        let sliceCount: Int
    }

    init(
        skill: CDAbsSkill,
        suggestion: ProgressionDecision,
        editing: SetLog? = nil,
        currentSession: Session? = nil,
        liveHRStats: (min: Int, max: Int, avg: Int)? = nil,
        isFinalRound: Bool = false,
        initialIsometric: Bool = false,
        onSave: @escaping (Entry) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.skill = skill
        self.suggestion = suggestion
        self.editing = editing
        self.currentSession = currentSession ?? editing?.session
        self.liveHRStats = liveHRStats
        self.isFinalRound = isFinalRound
        self.initialIsometric = initialIsometric
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        RatedSetForm(
            skill: RatedSkillInfo(skill),
            equipment: NoEquipment.self,
            suggestedDecision: suggestion,
            editing: draft,
            liveHR: liveHRStats.map { HRStats(min: $0.min, max: $0.max, avg: $0.avg) },
            config: RatedSetFormConfig(
                repsInfo: "1 rep is both sides of a skill once",
                slicesInfo: "Each slice is a 30-second isometric hold at a distinct position within the movement range — start, quarter, mid, three-quarter, end."
            ),
            initialIsometric: initialIsometric,
            header: { SkillAnimatedPoster(skill: skill, maxHeight: 80, cornerRadius: 8) },
            onSave: { entry in
                onSave(Entry(reps: entry.reps, rpt: entry.rpt, rpe: entry.rpe,
                             rpd: entry.rpd, notes: entry.notes, decision: entry.decision,
                             isometric: entry.isometric, sliceCount: entry.sliceCount))
            },
            onCancel: onCancel
        )
    }

    private var draft: RatedSetDraft<NoEquipment.Payload>? {
        guard let e = editing else { return nil }
        return RatedSetDraft(
            reps: Int(e.reps), rpt: Int(e.rpt), rpe: Int(e.rpe), rpd: Int(e.rpd),
            notes: e.notes ?? "", decision: e.decisionValue,
            isometric: e.isometric, sliceCount: Int(e.sliceCount),
            payload: nil,
            hr: e.hrAvg > 0 ? HRStats(min: Int(e.hrMin), max: Int(e.hrMax), avg: Int(e.hrAvg)) : nil
        )
    }
}
