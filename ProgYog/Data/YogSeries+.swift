//
//  YogSeries+.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//
//

import Foundation
import CoreData

@objc(YogSeries)
public class YogSeries: NSManagedObject { }

extension YogSeries {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<YogSeries> {
        return NSFetchRequest<YogSeries>(entityName: "YogSeries")
    }

    @NSManaged public var name: String?
    @NSManaged public var url: URL?
    @NSManaged public var skillFamilies: NSSet?

}

extension YogSeries {
    convenience init(name: String, url: URL, moc: NSManagedObjectContext) {
        self.init(context:moc)
        self.name = name
        self.url = url
    }
}

// MARK: Generated accessors for skillFamilies
extension YogSeries {

    @objc(addSkillFamiliesObject:)
    @NSManaged public func addToSkillFamilies(_ value: SkillFamily)

    @objc(removeSkillFamiliesObject:)
    @NSManaged public func removeFromSkillFamilies(_ value: SkillFamily)

    @objc(addSkillFamilies:)
    @NSManaged public func addToSkillFamilies(_ values: NSSet)

    @objc(removeSkillFamilies:)
    @NSManaged public func removeFromSkillFamilies(_ values: NSSet)

}

extension YogSeries: Identifiable { }
