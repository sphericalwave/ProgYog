//
//  CDAbsSkill+.swift
//  ProgYog
//

import Foundation
import CoreData
import UIKit

@objc(CDAbsSkill)
public class CDAbsSkill: NSManagedObject { }

extension CDAbsSkill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAbsSkill> {
        return NSFetchRequest<CDAbsSkill>(entityName: "CDAbsSkill")
    }

    @NSManaged public var bundleDepth: Int16
    @NSManaged public var customPhotoData: Data?
    @NSManaged public var customPhotosData: NSArray?
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
    }

    /// The hero image (idx 0) if one exists.
    var posterAssetName: String? { posterAssetNames.first }

    /// Custom photos added by the user (multiple). Prefers customPhotosData,
    /// falls back to the legacy single customPhotoData.
    var customPhotos: [Data] {
        get {
            if let arr = customPhotosData as? [Data], !arr.isEmpty { return arr }
            if let d = customPhotoData { return [d] }
            return []
        }
        set { customPhotosData = newValue.isEmpty ? nil : (newValue as NSArray) }
    }
}

