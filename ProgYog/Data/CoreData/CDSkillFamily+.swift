//
//  SkillFamily+.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//
//

import Foundation
import CoreData

@objc(CDSkillFamily)
public class CDSkillFamily: NSManagedObject { }

extension CDSkillFamily {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSkillFamily> {
        return NSFetchRequest<CDSkillFamily>(entityName: "CDSkillFamily")
    }

    @NSManaged public var name: String
    @NSManaged public var order: Int16
    @NSManaged public var series: String
    @NSManaged public var absSkills: NSSet
    @NSManaged public var yogSeries: CDYogSeries
}

extension CDSkillFamily {
    //FIXME: Depends on AbsSkills being loaded
    //Not an ideal initializer because it's not completely initialized
    //because the Series has to be associated
    //External knowledge of construction order is required.
    convenience init(json: JsonSkillFamily, moc: NSManagedObjectContext) { //FIXME: Naming
        self.init(context: moc)
        self.name = json.name
        self.order = Int16(json.order)
        self.series = json.series
        
        //Fetch Skills and Associate them
//        let skills = NSFetchRequest<AbsSkill>(entityName: "AbsSkill")
//        skills.predicate = NSPredicate(format: "family == %@", jsonSkillFam.name)
//        guard let famSkills = try? moc.fetch(skills) else { fatalError() }
//
//        print(famSkills)
//
//        self.addToAbsSkills(NSSet(array: famSkills))
    }
}

// MARK: Generated accessors for absSkills
extension CDSkillFamily {

    @objc(addAbsSkillsObject:)
    @NSManaged public func addToAbsSkills(_ value: CDAbsSkill)

    @objc(removeAbsSkillsObject:)
    @NSManaged public func removeFromAbsSkills(_ value: CDAbsSkill)

    @objc(addAbsSkills:)
    @NSManaged public func addToAbsSkills(_ values: NSSet)

    @objc(removeAbsSkills:)
    @NSManaged public func removeFromAbsSkills(_ values: NSSet)
}

extension CDSkillFamily: Identifiable { }
