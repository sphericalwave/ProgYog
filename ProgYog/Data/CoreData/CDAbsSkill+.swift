//
//  CDAbsSkill+.swift
//  ProgYog
//

import Foundation
import CoreData

@objc(CDAbsSkill)
public class CDAbsSkill: NSManagedObject { }

extension CDAbsSkill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAbsSkill> {
        return NSFetchRequest<CDAbsSkill>(entityName: "CDAbsSkill")
    }

    @NSManaged public var depth: Int16
    @NSManaged public var instructions: String
    @NSManaged public var name: String
    @NSManaged public var symetrical: Bool
    @NSManaged public var timeCode: Double
    @NSManaged public var series: String
    @NSManaged public var family: String
    @NSManaged public var url: URL
    @NSManaged public var setLogs: NSSet?
    @NSManaged public var skillFamily: CDSkillFamily?
}

extension CDAbsSkill {
    convenience init(json: JsonSkillData, moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = json.name
        self.depth = Int16(json.depth)
        self.instructions = json.instructions
        self.symetrical = json.symmetrical
        self.timeCode = json.timeCode
        self.family = json.skillFamily
        self.series = json.series
        self.url = json.url
    }
}

extension CDAbsSkill {
    @objc(addSetLogsObject:)
    @NSManaged public func addToSetLogs(_ value: SetLog)

    @objc(removeSetLogsObject:)
    @NSManaged public func removeFromSetLogs(_ value: SetLog)

    @objc(addSetLogs:)
    @NSManaged public func addToSetLogs(_ values: NSSet)

    @objc(removeSetLogs:)
    @NSManaged public func removeFromSetLogs(_ values: NSSet)
}

extension CDAbsSkill: Identifiable { }
