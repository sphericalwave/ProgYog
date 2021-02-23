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

    @NSManaged public var name: String
    @NSManaged public var order: Int16
    @NSManaged public var series: String
    @NSManaged public var absSkills: NSSet
    @NSManaged public var yogSeries: YogSeries
}

extension SkillFamily {
    //FIXME: Depends on AbsSkills being loaded
    //Not an ideal initializer because it's not completely initialized
    //because the Series has to be associated
    //External knowledge of construction order is required.
    convenience init(jsonSkillFam: JsonSkillFamily, moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = jsonSkillFam.name
        self.order = Int16(jsonSkillFam.order)
        
        //Fetch Skills and Associate them
        let skills = NSFetchRequest<AbsSkill>(entityName: "AbsSkill")
        skills.predicate = NSPredicate(format: "family == %@", jsonSkillFam.name)
        guard let famSkills = try? moc.fetch(skills) else { fatalError() }
        
        print(famSkills)
        
        self.addToAbsSkills(NSSet(object: famSkills))
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

extension SkillFamily: Identifiable { }
