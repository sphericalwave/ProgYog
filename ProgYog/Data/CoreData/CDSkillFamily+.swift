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

extension CDSkillFamily {
    /// Skills sorted by depth ascending. Zero when empty.
    var orderedAbsSkills: [CDAbsSkill] {
        let set = absSkills as? Set<CDAbsSkill> ?? []
        return set.sorted { $0.depth < $1.depth }
    }

    /// Max depth across all skills in this family. Zero when empty.
    var maxDepth: Int16 {
        let set = absSkills as? Set<CDAbsSkill> ?? []
        return set.map { $0.depth }.max() ?? 0
    }
}

extension Collection where Element == CDSkillFamily {
    /// Column-major flatten of every family's skills: first skill of every
    /// family, then each family's second skill, etc. Used to drive a
    /// carousel that cycles through a set of families' skills evenly.
    var carouselSkills: [CDAbsSkill] {
        let perFamily = sorted { $0.order < $1.order }.map(\.orderedAbsSkills)
        let maxCount = perFamily.map(\.count).max() ?? 0
        guard maxCount > 0 else { return [] }
        return (0..<maxCount).flatMap { depth in
            perFamily.compactMap { depth < $0.count ? $0[depth] : nil }
        }
    }
}
