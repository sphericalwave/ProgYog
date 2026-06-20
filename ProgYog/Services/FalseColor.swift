//
//  FalseColor.swift
//  ProgYog
//
//  False-color scale for the TACFIT TED ratings. Red marks the "bad" end of
//  each axis — poor form, hard exertion, or pain — fading through orange and
//  yellow to green as the value improves, like a thermal map.
//

import SwiftUI

enum FalseColor {
    /// Maps a 0...1 severity (0 = good/green, 1 = bad/red) to a false color.
    /// Hue runs from green (0.33) down to red (0.0).
    static func severity(_ t: Double) -> Color {
        let clamped = min(1, max(0, t))
        return Color(hue: 0.33 * (1 - clamped), saturation: 0.85, brightness: 0.9)
    }

    /// Technique 1–10: low = poor form = red, high = good form = green.
    static func technique(_ value: Int) -> Color {
        severity(Double(10 - value) / 9)
    }

    /// Exertion 1–10: high = hard = red, low = easy = green.
    static func exertion(_ value: Int) -> Color {
        severity(Double(value - 1) / 9)
    }

    /// Discomfort 1–10: high = pain = red, low = no discomfort = green.
    static func discomfort(_ value: Int) -> Color {
        severity(Double(value - 1) / 9)
    }
}
