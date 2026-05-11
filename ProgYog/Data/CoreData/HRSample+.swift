//
//  HRSample+.swift
//  ProgYog
//

import Foundation
import CoreData

@objc(HRSample)
public class HRSample: NSManagedObject { }

extension HRSample {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HRSample> {
        return NSFetchRequest<HRSample>(entityName: "HRSample")
    }

    @NSManaged public var t: Double
    @NSManaged public var bpm: Int16
    @NSManaged public var setLog: SetLog?
}

extension HRSample: Identifiable { }
