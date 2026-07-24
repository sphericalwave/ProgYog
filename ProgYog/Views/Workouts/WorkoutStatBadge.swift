//
//  WorkoutStatBadge.swift
//  ProgYog
//
//  Pentagon-esque "rank badge" for a workout's most recent session:
//  completion % inside a polygon that morphs from a triangle (0%) up
//  through a nonagon (90%) to a near-perfect circle (100%), filled with a
//  radial gradient and outlined in white. Colored by a false-color scheme
//  that sweeps red → the visible spectrum → black as the percent rises.
//  Round breakdown (dynamic vs. isometric) sits alongside it.
//

import SwiftUI

struct WorkoutStatBadge: View {
    let title: String
    /// 0...100, or nil when there's no session yet (badge renders "—").
    let percent: Double?
    let dynamicRounds: Int
    let isometricRounds: Int

    private let badgeSize: CGFloat = 84
    private let borderExtra: CGFloat = 10
    private let borderWidth: CGFloat = 3

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                BadgePolygon(sides: sides)
                    .stroke(Color.white, lineWidth: borderWidth)
                    .frame(width: badgeSize + borderExtra, height: badgeSize + borderExtra)
                BadgePolygon(sides: sides)
                    .fill(Self.fillGradient(percent: percent ?? 0))
                    .frame(width: badgeSize, height: badgeSize)
                Text(label)
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 1.5)
            }
            .animation(.easeInOut(duration: 0.35), value: sides)
            .animation(.easeInOut(duration: 0.35), value: percent)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.headline, design: .monospaced))
                Text("\(dynamicRounds) dynamic \(dynamicRounds == 1 ? "round" : "rounds")")
                Text("\(isometricRounds) isometric \(isometricRounds == 1 ? "round" : "rounds")")
            }
            .font(.system(.subheadline, design: .monospaced).weight(.medium))
            Spacer()
        }
    }

    private var label: String {
        guard let percent else { return "—" }
        return "\(Int(percent.rounded()))%"
    }

    /// 3 (triangle) at 0%, up through 9 (nonagon) by 90%, then rapidly up
    /// to a many-sided polygon that reads as a circle by 100%.
    private var sides: Double {
        let t = min(max(percent ?? 0, 0), 100)
        if t <= 90 {
            return 3 + 6 * (t / 90)
        } else {
            return 9 + 51 * ((t - 90) / 10)
        }
    }

    /// Red (0%) sweeps through the visible spectrum to violet by 90%, then
    /// fades to black over the last 10 points.
    private static func falseColorComponents(percent: Double) -> (hue: Double, saturation: Double, brightness: Double) {
        let t = min(max(percent, 0), 100) / 100
        let spectrumT = min(t / 0.9, 1)
        let blackT = max((t - 0.9) / 0.1, 0)
        let hue = spectrumT * (300.0 / 360.0)
        let brightness = (1 - 0.35 * spectrumT) * (1 - blackT)
        let saturation = 1 - 0.1 * blackT
        return (hue, saturation, max(brightness, 0.05))
    }

    /// Circular gradient: a lightened highlight at the center fading to
    /// the true false-color at the edge, for a glossy badge look.
    private static func fillGradient(percent: Double) -> RadialGradient {
        let c = falseColorComponents(percent: percent)
        let base = Color(hue: c.hue, saturation: c.saturation, brightness: c.brightness)
        let highlight = Color(hue: c.hue, saturation: max(c.saturation - 0.35, 0), brightness: min(c.brightness + 0.35, 1))
        return RadialGradient(colors: [highlight, base], center: .center, startRadius: 2, endRadius: 46)
    }
}

/// Regular polygon, point up, inscribed in the given rect. `sides` is a
/// continuous, animatable value — fractional values smoothly morph the
/// boundary between the neighboring integer polygon shapes, and large
/// values (~50+) read as a circle.
private struct BadgePolygon: Shape {
    var sides: Double

    var animatableData: Double {
        get { sides }
        set { sides = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let sampleCount = 240
        var path = Path()
        for i in 0...sampleCount {
            let theta = -CGFloat.pi / 2 + CGFloat(i) / CGFloat(sampleCount) * (2 * .pi)
            let r = Self.polygonRadius(sides: max(sides, 3), theta: theta)
            let point = CGPoint(x: center.x + radius * r * cos(theta), y: center.y + radius * r * sin(theta))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// Normalized (0...1) distance from center to a regular polygon's
    /// boundary at angle `theta`, with vertices touching 1 and edge
    /// midpoints dipping to the apothem/circumradius ratio. Continuous in
    /// `sides`, so fractional values interpolate smoothly.
    private static func polygonRadius(sides: Double, theta: CGFloat) -> CGFloat {
        let n = CGFloat(sides)
        let segment = 2 * CGFloat.pi / n
        let halfSegment = segment / 2
        let shifted = theta + CGFloat.pi / 2
        var a = shifted.truncatingRemainder(dividingBy: segment)
        if a < 0 { a += segment }
        let rel = a - halfSegment
        return cos(halfSegment) / cos(rel)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        WorkoutStatBadge(title: "progYog A", percent: 10, dynamicRounds: 5, isometricRounds: 0)
        WorkoutStatBadge(title: "progYog A", percent: 45, dynamicRounds: 3, isometricRounds: 2)
        WorkoutStatBadge(title: "progYog A", percent: 80, dynamicRounds: 4, isometricRounds: 1)
        WorkoutStatBadge(title: "progYog A", percent: 100, dynamicRounds: 5, isometricRounds: 0)
        WorkoutStatBadge(title: "progYog A", percent: nil, dynamicRounds: 0, isometricRounds: 0)
    }
    .padding()
    .background(Color.black)
}
#endif
