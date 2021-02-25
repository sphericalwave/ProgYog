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
    //FIXME: Depends on SkillFamilys being loaded
    //Not an ideal initializer because it's not completely initialized
    //because the Series has to be associated
    //External knowledge of construction order is required.
    convenience init(row: JsonSkillData, moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = row.series
        self.url = row.url
        
        //Fetch SkillFamilys and Associate them
        let skillFamRequest = NSFetchRequest<SkillFamily>(entityName: "SkillFamily")
        skillFamRequest.predicate = NSPredicate(format: "series == %@", row.series)
        guard let skillFams = try? moc.fetch(skillFamRequest) else { fatalError() }
        self.addToSkillFamilies(NSSet(object: skillFams))
    }
    
    convenience init(json: JsonYogSeries, moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = json.name
        self.url = json.url
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
