//
//  YogSeries+.swift
//  ProgYog
//
//  Created by Aaron Anthony on 2021-02-22.
//
//

import Foundation
import CoreData

@objc(CDYogSeries)
public class CDYogSeries: NSManagedObject { }

extension CDYogSeries {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDYogSeries> {
        return NSFetchRequest<CDYogSeries>(entityName: "CDYogSeries")
    }

    @NSManaged public var name: String?
    @NSManaged public var url: URL?
    @NSManaged public var skillFamilies: NSSet?
}

extension CDYogSeries {
    //FIXME: Depends on SkillFamilys being loaded
    //Not an ideal initializer because it's not completely initialized
    //because the Series has to be associated
    //External knowledge of construction order is required.
    convenience init(row: JsonSkillData, moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = row.series
        self.url = row.url
        
        //Fetch SkillFamilys and Associate them
        let skillFamRequest = NSFetchRequest<CDSkillFamily>(entityName: "CDSkillFamily")
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
extension CDYogSeries {
    
    @objc(addSkillFamiliesObject:)
    @NSManaged public func addToSkillFamilies(_ value: CDSkillFamily)

    @objc(removeSkillFamiliesObject:)
    @NSManaged public func removeFromSkillFamilies(_ value: CDSkillFamily)

    @objc(addSkillFamilies:)
    @NSManaged public func addToSkillFamilies(_ values: NSSet)

    @objc(removeSkillFamilies:)
    @NSManaged public func removeFromSkillFamilies(_ values: NSSet)
}

extension CDYogSeries: Identifiable { }
