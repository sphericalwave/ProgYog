//
//  AbsSkill+.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//
//

import Foundation
import CoreData

@objc(AbsSkill)
public class AbsSkill: NSManagedObject { }

extension AbsSkill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AbsSkill> {
        return NSFetchRequest<AbsSkill>(entityName: "AbsSkill")
    }

    @NSManaged public var depth: Int16
    @NSManaged public var instructions: String?
    @NSManaged public var name: String?
    @NSManaged public var symetrical: Bool
    @NSManaged public var timeCode: Double
    @NSManaged public var crtSkills: NSSet?
    @NSManaged public var skillFamily: SkillFamily?

}

extension AbsSkill {
    convenience init(jsonAbsSkill: JsonAbsSkill, moc: NSManagedObjectContext) {
        self.init(context:moc)
        self.name = jsonAbsSkill.name
        self.depth = Int16(jsonAbsSkill.depth)
        self.instructions = jsonAbsSkill.instructions
        self.symetrical = jsonAbsSkill.symmetrical  //TODO
        //self.timeCode = jsonAbsSkill.timeCode
        //TODO: missing skill family
    }
}

// MARK: Generated accessors for crtSkills
extension AbsSkill {

    @objc(addCrtSkillsObject:)
    @NSManaged public func addToCrtSkills(_ value: CrtSkill)

    @objc(removeCrtSkillsObject:)
    @NSManaged public func removeFromCrtSkills(_ value: CrtSkill)

    @objc(addCrtSkills:)
    @NSManaged public func addToCrtSkills(_ values: NSSet)

    @objc(removeCrtSkills:)
    @NSManaged public func removeFromCrtSkills(_ values: NSSet)

}

extension AbsSkill: Identifiable { }
