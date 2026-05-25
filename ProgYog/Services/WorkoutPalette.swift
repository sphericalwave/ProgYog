//
//  WorkoutPalette.swift
//  ProgYog
//
//  Single source of truth for workout-code → chip color and the
//  canonical A..E code list.
//

import SwiftUI

enum WorkoutPalette {
    static let codes = ["A", "B", "C", "D", "E"]

    static func color(for code: String) -> Color {
        switch code {
        case "A": return .red
        case "B": return .blue
        case "C": return .green
        case "D": return .purple
        case "E": return .orange
        default:  return .gray
        }
    }
}
