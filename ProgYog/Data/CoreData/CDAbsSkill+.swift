//
//  CDAbsSkill+.swift
//  ProgYog
//

import Foundation
import CoreData
#if os(iOS)
import UIKit
#endif

@objc(CDAbsSkill)
public class CDAbsSkill: NSManagedObject { }

extension CDAbsSkill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAbsSkill> {
        return NSFetchRequest<CDAbsSkill>(entityName: "CDAbsSkill")
    }

    @NSManaged public var bundleDepth: Int16
    @NSManaged public var customPhotoData: Data?
    @NSManaged public var depth: Int16
    @NSManaged public var hideBundleImages: Bool
    @NSManaged public var instructions: String
    @NSManaged public var name: String
    @NSManaged public var symetrical: Bool
    @NSManaged public var timeCode: Double
    @NSManaged public var series: String
    @NSManaged public var family: String
    @NSManaged public var url: URL
    @NSManaged public var sliceCount: Int16
    @NSManaged public var photos: NSSet?
    @NSManaged public var setLogs: NSSet?
    @NSManaged public var skillFamily: CDSkillFamily?
}

extension CDAbsSkill {
    convenience init(json: JsonSkillData, moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.name = json.name
        self.depth = Int16(json.depth)
        self.instructions = json.instructions
        self.symetrical = json.symmetrical
        self.timeCode = json.timeCode
        self.family = json.skillFamily
        self.series = json.series
        self.url = json.url
    }
}

extension CDAbsSkill {
    @objc(addSetLogsObject:)
    @NSManaged public func addToSetLogs(_ value: SetLog)

    @objc(removeSetLogsObject:)
    @NSManaged public func removeFromSetLogs(_ value: SetLog)

    @objc(addSetLogs:)
    @NSManaged public func addToSetLogs(_ values: NSSet)

    @objc(removeSetLogs:)
    @NSManaged public func removeFromSetLogs(_ values: NSSet)
}

extension CDAbsSkill: Identifiable { }

extension CDAbsSkill {
    /// Asset-catalog stem under the "Poses" namespace, e.g. "Poses/A-1-2".
    /// Uses bundleDepth when set (non-zero) so images survive depth reordering.
    var posterStem: String {
        let order = skillFamily?.order ?? 0
        let d = bundleDepth != 0 ? bundleDepth : depth
        return "Poses/\(series)-\(order)-\(d)"
    }

    private static var posterNamesCache: [String: [String]] = [:]

    /// All bundle-resident pose images for this skill, in extraction order.
    var posterAssetNames: [String] {
        #if os(iOS)
        guard !hideBundleImages else { return [] }
        let stem = posterStem
        if let cached = Self.posterNamesCache[stem] { return cached }
        var names: [String] = []
        var idx = 0
        while UIImage(named: "\(stem)-\(idx)") != nil {
            names.append("\(stem)-\(idx)")
            idx += 1
        }
        Self.posterNamesCache[stem] = names
        return names
        #else
        return []
        #endif
    }

    /// The hero image (idx 0) if one exists.
    var posterAssetName: String? { posterAssetNames.first }

    /// All photos for this skill, sorted by order. Backed by CDSkillPhoto relationship.
    var customPhotos: [Data] {
        get {
            let set = (photos as? Set<CDSkillPhoto>) ?? []
            return set.sorted { $0.order < $1.order }.compactMap { $0.data }
        }
        set {
            if let existing = photos as? Set<CDSkillPhoto> {
                existing.forEach { managedObjectContext?.delete($0) }
            }
            guard !newValue.isEmpty, let moc = managedObjectContext else {
                photos = nil
                return
            }
            var newSet: Set<CDSkillPhoto> = []
            for (idx, data) in newValue.enumerated() {
                let photo = CDSkillPhoto(context: moc)
                photo.data = data
                photo.order = Int16(idx)
                photo.skill = self
                newSet.insert(photo)
            }
            photos = newSet as NSSet
        }
    }
}

