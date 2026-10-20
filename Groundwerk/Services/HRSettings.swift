//
//  HRSettings.swift
//  Groundwerk
//
//  Max-heart-rate preference. The BLE strap plumbing lives in HeartRateKit
//  (`HeartRateMonitor`); this is just the user's own max-HR setting.
//

import Foundation

/// User max-heart-rate setting, persisted via `@AppStorage`. The default is
/// the `220 − age` estimate; a non-zero manual override replaces it.
enum HRSettings {
    static let ageKey = "userAge"
    static let overrideKey = "hrMaxOverride"

    /// `manualOverride == 0` means "no override — use the 220 − age estimate".
    static func effectiveMax(age: Int, manualOverride: Int) -> Int {
        manualOverride > 0 ? manualOverride : max(220 - age, 1)
    }
}
