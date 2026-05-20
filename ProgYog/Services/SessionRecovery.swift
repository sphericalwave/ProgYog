//
//  SessionRecovery.swift
//  ProgYog
//
//  Value-type snapshots of Session + SetLog (+ HR samples) and the inverse
//  restore functions. Used by UndoStack to recover from accidental delete.
//  Snapshots capture VALUES; never hold managed objects in the stack —
//  they're invalid after the delete + save round-trip.
//

import Foundation
import CoreData

// MARK: - Snapshot value types

struct HRSampleSnapshot {
    let t: Double
    let bpm: Int16
}

struct SetLogSnapshot {
    let id: UUID
    let roundIndex: Int16
    let orderInRound: Int16
    let reps: Int16
    let rom: Int16
    let rpt: Int16
    let rpe: Int16
    let rpd: Int16
    let rptNote: String?
    let rpeNote: String?
    let rpdNote: String?
    let notes: String?
    let durationSec: Int16
    let decision: String
    let hrAvg: Int16
    let hrMin: Int16
    let hrMax: Int16
    let loggedAt: Date
    /// Skills are seeded catalog entries — never deleted in undo scope —
    /// so the objectID stays valid across restore.
    let absSkillID: NSManagedObjectID?
    let hrSamples: [HRSampleSnapshot]
}

struct SessionSnapshot {
    let id: UUID
    let startedAt: Date
    let endedAt: Date?
    let workoutCode: String
    let notes: String?
    let setLogs: [SetLogSnapshot]
}

// MARK: - Snapshot / restore

@MainActor
enum SessionRecovery {

    // Snapshot --------------------------------------------------------------

    static func snapshot(_ s: Session) -> SessionSnapshot {
        SessionSnapshot(
            id: s.id,
            startedAt: s.startedAt,
            endedAt: s.endedAt,
            workoutCode: s.workoutCode,
            notes: s.notes,
            setLogs: s.orderedSetLogs.map { snapshot($0) }
        )
    }

    static func snapshot(_ log: SetLog) -> SetLogSnapshot {
        SetLogSnapshot(
            id: log.id,
            roundIndex: log.roundIndex,
            orderInRound: log.orderInRound,
            reps: log.reps,
            rom: log.rom,
            rpt: log.rpt,
            rpe: log.rpe,
            rpd: log.rpd,
            rptNote: log.rptNote,
            rpeNote: log.rpeNote,
            rpdNote: log.rpdNote,
            notes: log.notes,
            durationSec: log.durationSec,
            decision: log.decision,
            hrAvg: log.hrAvg,
            hrMin: log.hrMin,
            hrMax: log.hrMax,
            loggedAt: log.loggedAt,
            absSkillID: log.absSkill?.objectID,
            hrSamples: log.orderedHRSamples.map { HRSampleSnapshot(t: $0.t, bpm: $0.bpm) }
        )
    }

    // Restore ---------------------------------------------------------------

    @discardableResult
    static func restore(_ snap: SessionSnapshot, into moc: NSManagedObjectContext) -> Session {
        let s = Session(context: moc)
        s.id = snap.id
        s.startedAt = snap.startedAt
        s.endedAt = snap.endedAt
        s.workoutCode = snap.workoutCode
        s.notes = snap.notes
        for logSnap in snap.setLogs {
            _ = restore(logSnap, into: moc, session: s)
        }
        return s
    }

    @discardableResult
    static func restore(_ snap: SetLogSnapshot,
                        into moc: NSManagedObjectContext,
                        session: Session) -> SetLog {
        let log = SetLog(context: moc)
        log.id = snap.id
        log.session = session
        log.roundIndex = snap.roundIndex
        log.orderInRound = snap.orderInRound
        log.reps = snap.reps
        log.rom = snap.rom
        log.rpt = snap.rpt
        log.rpe = snap.rpe
        log.rpd = snap.rpd
        log.rptNote = snap.rptNote
        log.rpeNote = snap.rpeNote
        log.rpdNote = snap.rpdNote
        log.notes = snap.notes
        log.durationSec = snap.durationSec
        log.decision = snap.decision
        log.hrAvg = snap.hrAvg
        log.hrMin = snap.hrMin
        log.hrMax = snap.hrMax
        log.loggedAt = snap.loggedAt
        if let skillID = snap.absSkillID,
           let skill = try? moc.existingObject(with: skillID) as? CDAbsSkill {
            log.absSkill = skill
        }
        for sampleSnap in snap.hrSamples {
            let sample = HRSample(context: moc)
            sample.t = sampleSnap.t
            sample.bpm = sampleSnap.bpm
            sample.setLog = log
        }
        return log
    }
}
