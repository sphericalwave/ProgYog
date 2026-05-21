//
//  SessionEditor.swift
//  ProgYog
//
//  Pure helpers that mutate a Session's date pair / completed state.
//  Saving + calendar mirroring stay in the view layer — these are
//  side-effect-free so they can be unit tested without SwiftUI.
//

import Foundation

@MainActor
enum SessionEditor {

    /// Move `startedAt` to `newStart`. If `endedAt` is set, shift it by
    /// the same delta so the session's duration is preserved.
    static func shiftStart(_ session: Session, to newStart: Date) {
        if let end = session.endedAt {
            let delta = newStart.timeIntervalSince(session.startedAt)
            session.endedAt = end.addingTimeInterval(delta)
        }
        session.startedAt = newStart
    }

    /// Set `endedAt`, clamped to `>= session.startedAt` so end never
    /// lands before start regardless of where the value came from.
    static func setEnd(_ session: Session, to newEnd: Date) {
        session.endedAt = max(newEnd, session.startedAt)
    }

    /// Toggle the completed state. Marking completed picks
    /// `max(now, startedAt)` as the new endedAt so it never sits before
    /// start; un-marking clears endedAt back to nil.
    static func setCompleted(_ session: Session, _ completed: Bool) {
        if completed {
            session.endedAt = max(Date(), session.startedAt)
        } else {
            session.endedAt = nil
        }
    }
}
