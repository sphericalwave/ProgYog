//
//  CDSkillPhoto+.swift
//  ProgYog
//

import Foundation
import CoreData

@objc(CDSkillPhoto)
public class CDSkillPhoto: NSManagedObject { }

extension CDSkillPhoto {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSkillPhoto> {
        return NSFetchRequest<CDSkillPhoto>(entityName: "CDSkillPhoto")
    }

    @NSManaged public var data: Data
    @NSManaged public var order: Int16
    @NSManaged public var skill: CDAbsSkill?
}

extension CDSkillPhoto: Identifiable { }
