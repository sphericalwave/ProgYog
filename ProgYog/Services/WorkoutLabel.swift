//
//  WorkoutLabel.swift
//  ProgYog
//
//  Single source of truth for the user-facing workout name.
//  `Session.workoutCode` ("A".."E") stays the internal identifier;
//  this helper prefixes it for display.
//

import Foundation

enum WorkoutLabel {
    /// "progYog A" for code "A".
    static func display(forCode code: String) -> String {
        "progYog \(code)"
    }

    static func display(for session: Session) -> String {
        display(forCode: session.workoutCode)
    }
}
