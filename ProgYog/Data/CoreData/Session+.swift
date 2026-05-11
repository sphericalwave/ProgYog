//
//  Session+.swift
//  ProgYog
//

import Foundation
import CoreData

@objc(Session)
public class Session: NSManagedObject { }

extension Session {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged public var id: UUID
    @NSManaged public var startedAt: Date
    @NSManaged public var endedAt: Date?
    @NSManaged public var workoutCode: String
    @NSManaged public var notes: String?
    @NSManaged public var setLogs: NSSet?
}

extension Session {
    convenience init(workoutCode: String, moc: NSManagedObjectContext) {
        self.init(context: moc)
        self.id = UUID()
        self.startedAt = Date()
        self.workoutCode = workoutCode
    }

    var orderedSetLogs: [SetLog] {
        let set = setLogs as? Set<SetLog> ?? []
        return set.sorted {
            if $0.roundIndex != $1.roundIndex { return $0.roundIndex < $1.roundIndex }
            return $0.orderInRound < $1.orderInRound
        }
    }
}

extension Session {
    @objc(addSetLogsObject:)
    @NSManaged public func addToSetLogs(_ value: SetLog)

    @objc(removeSetLogsObject:)
    @NSManaged public func removeFromSetLogs(_ value: SetLog)

    @objc(addSetLogs:)
    @NSManaged public func addToSetLogs(_ values: NSSet)

    @objc(removeSetLogs:)
    @NSManaged public func removeFromSetLogs(_ values: NSSet)
}

extension Session: Identifiable { }
