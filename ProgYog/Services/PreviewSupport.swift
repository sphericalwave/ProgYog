//
//  PreviewSupport.swift
//  ProgYog
//
//  In-memory AppServices seeded with sample catalog + a session
//  for use by SwiftUI #Preview blocks. Debug-only.
//

#if DEBUG
import CoreData
import Foundation

@MainActor
enum PreviewSupport {
    static let services: AppServices = {
        let s = AppServices(inMemory: true)
        seed(in: s.coreData.moc)
        s.coreData.save()
        return s
    }()

    static let sampleSession: Session = {
        _ = services
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        fr.fetchLimit = 1
        if let s = (try? services.coreData.moc.fetch(fr))?.first { return s }
        let session = Session(workoutCode: "A", moc: services.coreData.moc)
        try? services.coreData.moc.save()
        return session
    }()

    static let sampleSkill: CDAbsSkill = {
        _ = services
        let moc = services.coreData.moc
        let fr: NSFetchRequest<CDAbsSkill> = CDAbsSkill.fetchRequest()
        fr.predicate = NSPredicate(format: "series == %@ AND family == %@ AND depth == 2", "A", "Up Down Dog")
        fr.fetchLimit = 1
        if let s = (try? moc.fetch(fr))?.first { return s }
        let skill = CDAbsSkill(context: moc)
        skill.name = "Extended Knee Toe Point"
        skill.depth = 2
        skill.family = "Up Down Dog"
        skill.series = "A"
        skill.instructions = "Step back into a rear lunge, with your feet parallel, and shoulder width apart from each other. Exhale and bring your rear knee up and to chest. Extend and lock knee."
        skill.symetrical = true
        skill.timeCode = 75
        skill.url = URL(string: "https://example.com")!
        try? moc.save()
        return skill
    }()

    static let sampleFamily: CDSkillFamily = {
        _ = services
        let moc = services.coreData.moc
        let fr: NSFetchRequest<CDSkillFamily> = CDSkillFamily.fetchRequest()
        fr.predicate = NSPredicate(format: "series == %@ AND order == 1", "A")
        fr.fetchLimit = 1
        if let f = (try? moc.fetch(fr))?.first { return f }
        let family = CDSkillFamily(context: moc)
        family.name = "Up Down Dog"
        family.order = 1
        family.series = "A"
        try? moc.save()
        return family
    }()

    private static func seed(in moc: NSManagedObjectContext) {
        let placeholderURL = URL(string: "https://example.com")!

        // Two workouts (A and B) with two families each, 5 levels each
        let workouts: [(code: String, families: [(order: Int, name: String, skills: [String])])] = [
            (
                "A",
                [
                    (1, "Up Down Dog", ["Shallow Lunge Knee Lift", "Extended Knee Toe Point", "Locking Arms Overhead", "Locked Arms Overhead", "Walking Stick"]),
                    (2, "Leg Balance", ["Shallow Lunge Knee Lift", "Extended Knee Toe Point", "Locking Arms Overhead", "Locked Arms Overhead", "Walking Stick"]),
                    (3, "Twisting Table", ["Shinbox Twist", "Table Lift", "Revolving Tripod", "Three Leg Kick", "L Seat"]),
                    (4, "Lunge Twist", ["Side Lunge", "Internal Twist", "Jumper Lunge", "Jumper Bind", "Jumper Hold"]),
                ]
            ),
            (
                "B",
                [
                    (1, "Forward Fold", ["Clasped Hand & Lap", "Extending Knees", "Lifting Arms", "Backbend", "Forward Fold"]),
                    (2, "Hurdler", ["Knee Lift", "Leg Swoop", "Shinbox Switch", "Shinbox Block Twist", "Blocked Hold"]),
                ]
            ),
        ]

        var skillByName: [String: CDAbsSkill] = [:]
        for w in workouts {
            let series = CDYogSeries(context: moc)
            series.name = w.code
            series.url = placeholderURL
            for f in w.families {
                let family = CDSkillFamily(context: moc)
                family.name = f.name
                family.order = Int16(f.order)
                family.series = w.code
                family.yogSeries = series
                for (depth, skillName) in f.skills.enumerated() {
                    let skill = CDAbsSkill(context: moc)
                    skill.name = skillName
                    skill.depth = Int16(depth + 1)
                    skill.instructions = "Press off the mid-foot and exhale into the pose. Keep elbows locked. Hold for the duration without breaking form."
                    skill.symetrical = (depth % 2 == 0)
                    skill.timeCode = 75
                    skill.family = f.name
                    skill.series = w.code
                    skill.url = placeholderURL
                    skill.skillFamily = family
                    skillByName["\(w.code)/\(f.name)/\(depth+1)"] = skill
                }
            }
        }

        // Three historical workout-A sessions plus today's, so the
        // SetLogSheet trend chart has multiple data points and a clear
        // "highlight current session" effect for the sample skill.
        let day: TimeInterval = 24 * 3600
        let historyOffsetsAndMetrics: [(daysAgo: Double, metrics: [(rpt: Int16, rpe: Int16, rpd: Int16, reps: Int16, decision: String, notes: String?)])] = [
            (
                14,
                [
                    (5, 7, 5, 6, "hold",     "First go-round, struggled to keep heels down."),
                    (5, 7, 4, 6, "hold",     nil),
                    (4, 8, 5, 5, "regress",  "Twisting hurt the low back."),
                    (4, 8, 5, 5, "regress",  nil),
                ]
            ),
            (
                7,
                [
                    (6, 7, 4, 8, "hold",     "Better today, kept the heels closer."),
                    (6, 7, 3, 8, "progress", "Found rhythm on the second rep."),
                    (5, 8, 4, 6, "hold",     nil),
                    (5, 7, 4, 6, "hold",     nil),
                ]
            ),
            (
                3,
                [
                    (7, 6, 3, 10, "progress", "Hip is finally opening up."),
                    (7, 7, 3, 10, "progress", nil),
                    (6, 7, 3, 9,  "hold",     nil),
                    (6, 7, 3, 9,  "hold",     nil),
                ]
            ),
        ]

        let familyOrder = ["Up Down Dog", "Leg Balance", "Twisting Table", "Lunge Twist"]

        for (daysAgo, metrics) in historyOffsetsAndMetrics {
            let s = Session(workoutCode: "A", moc: moc)
            s.startedAt = Date().addingTimeInterval(-daysAgo * day)
            s.endedAt = Date().addingTimeInterval(-daysAgo * day + 1800)
            s.notes = nil
            for (idx, famName) in familyOrder.enumerated() {
                guard let skill = skillByName["A/\(famName)/2"] else { continue }
                let m = metrics[idx]
                let log = SetLog(context: moc)
                log.id = UUID()
                log.session = s
                log.absSkill = skill
                log.roundIndex = 0
                log.orderInRound = Int16(idx)
                log.reps = m.reps
                log.rpt = m.rpt
                log.rpe = m.rpe
                log.rpd = m.rpd
                log.notes = m.notes
                log.durationSec = 60
                log.decision = m.decision
                log.loggedAt = s.startedAt.addingTimeInterval(Double(idx) * 120)
            }
        }

        // Today's session — the one used as the "current" highlight in previews.
        let session = Session(workoutCode: "A", moc: moc)
        session.startedAt = Date().addingTimeInterval(-3600)
        session.endedAt = Date().addingTimeInterval(-2400)
        session.notes = "Felt good today; left hip warmed up after round 2."

        let todayMetrics: [(rpt: Int16, rpe: Int16, rpd: Int16, reps: Int16, decision: String, notes: String?)] = [
            (8, 7, 2, 12, "progress", "Smooth, locked elbows held the whole minute."),
            (7, 6, 3, 10, "hold",     nil),
            (6, 8, 4, 8,  "hold",     "Tight thoracic — switch sides at 30s felt rough."),
            (4, 9, 6, 6,  "regress",  "Knee twinge on the right side."),
        ]

        for (idx, famName) in familyOrder.enumerated() {
            guard let skill = skillByName["A/\(famName)/2"] else { continue }
            let m = todayMetrics[idx]
            let log = SetLog(context: moc)
            log.id = UUID()
            log.session = session
            log.absSkill = skill
            log.roundIndex = 0
            log.orderInRound = Int16(idx)
            log.reps = m.reps
            log.rpt = m.rpt
            log.rpe = m.rpe
            log.rpd = m.rpd
            log.notes = m.notes
            log.durationSec = 60
            log.decision = m.decision
            log.loggedAt = Date().addingTimeInterval(-3600 + Double(idx) * 120)
            log.hrAvg = Int16(120 + idx * 5)
            log.hrMin = Int16(100 + idx * 3)
            log.hrMax = Int16(135 + idx * 4)
            for t in stride(from: 0, through: 60, by: 5) {
                let sample = HRSample(context: moc)
                sample.t = Double(t)
                sample.bpm = Int16(115 + idx * 4 + Int.random(in: -5...10))
                sample.setLog = log
            }
        }
    }
}
#endif
