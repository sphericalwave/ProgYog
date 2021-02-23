//
//  SkillFamily+.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//
//

import Foundation
import CoreData

@objc(SkillFamily)
public class SkillFamily: NSManagedObject { }

extension SkillFamily {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SkillFamily> {
        return NSFetchRequest<SkillFamily>(entityName: "SkillFamily")
    }

    @NSManaged public var name: String?
    @NSManaged public var order: Int16
    @NSManaged public var absSkills: NSSet?
    @NSManaged public var series: YogSeries?

}

extension SkillFamily {
    convenience init(name: String, order: Int, absSkills: [AbsSkill], moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = name
        self.order = Int16(order)
        //TODO: Manual Codegen Required...Incoming
//        for skill in absSkills {
//            self.
//        }
    }
}

// MARK: Generated accessors for absSkills
extension SkillFamily {

    @objc(addAbsSkillsObject:)
    @NSManaged public func addToAbsSkills(_ value: AbsSkill)

    @objc(removeAbsSkillsObject:)
    @NSManaged public func removeFromAbsSkills(_ value: AbsSkill)

    @objc(addAbsSkills:)
    @NSManaged public func addToAbsSkills(_ values: NSSet)

    @objc(removeAbsSkills:)
    @NSManaged public func removeFromAbsSkills(_ values: NSSet)

}

extension SkillFamily : Identifiable {

}
