//
//  CrtSkill+CoreDataProperties.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//
//

import Foundation
import CoreData

@objc(CrtSkill)
public class CrtSkill: NSManagedObject { }

extension CrtSkill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CrtSkill> {
        return NSFetchRequest<CrtSkill>(entityName: "CrtSkill")
    }

    @NSManaged public var control: Int16
    @NSManaged public var date: Date?
    @NSManaged public var discomfort: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var rom: Int16
    @NSManaged public var absSkill: AbsSkill?

}

extension CrtSkill: Identifiable { }
