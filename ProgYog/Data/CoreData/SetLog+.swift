//
//  SetLog+.swift
//  ProgYog
//

import Foundation
import CoreData

@objc(SetLog)
public class SetLog: NSManagedObject { }

extension SetLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SetLog> {
        return NSFetchRequest<SetLog>(entityName: "SetLog")
    }

    @NSManaged public var id: UUID
    @NSManaged public var roundIndex: Int16
    @NSManaged public var orderInRound: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var rom: Int16
    @NSManaged public var rpt: Int16
    @NSManaged public var rpe: Int16
    @NSManaged public var rpd: Int16
    @NSManaged public var rptNote: String?
    @NSManaged public var rpeNote: String?
    @NSManaged public var rpdNote: String?
    @NSManaged public var notes: String?
    @NSManaged public var durationSec: Int16
    @NSManaged public var isometric: Bool
    @NSManaged public var sliceCount: Int16
    @NSManaged public var decision: String
    @NSManaged public var hrAvg: Int16
    @NSManaged public var hrMin: Int16
    @NSManaged public var hrMax: Int16
    @NSManaged public var loggedAt: Date
    @NSManaged public var session: Session?
    @NSManaged public var absSkill: CDAbsSkill?
    @NSManaged public var hrSamples: NSSet?
}

extension SetLog {
    var decisionValue: ProgressionDecision {
        ProgressionDecision(rawValue: decision) ?? .repeat
    }

    var ratedSet: RatedSet {
        RatedSet(rpt: Int(rpt), rpe: Int(rpe), rpd: Int(rpd), loggedAt: loggedAt)
    }

    var orderedHRSamples: [HRSample] {
        let set = hrSamples as? Set<HRSample> ?? []
        return set.sorted { $0.t < $1.t }
    }

    /// Set meets the inclusive completion-quality bar
    /// (RPT ≥ 8, RPE ≤ 6, RPD ≤ 1, ROM ≥ 95).
    var qualifiesForCompletion: Bool {
        rpt >= CompletionScorer.rptMin
            && rpe <= CompletionScorer.rpeMax
            && rpd <= CompletionScorer.rpdMax
            && rom >= CompletionScorer.romMin
    }
}

extension SetLog {
    @objc(addHrSamplesObject:)
    @NSManaged public func addToHrSamples(_ value: HRSample)

    @objc(removeHrSamplesObject:)
    @NSManaged public func removeFromHrSamples(_ value: HRSample)

    @objc(addHrSamples:)
    @NSManaged public func addToHrSamples(_ values: NSSet)

    @objc(removeHrSamples:)
    @NSManaged public func removeFromHrSamples(_ values: NSSet)
}

extension SetLog: Identifiable { }
