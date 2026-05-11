//
//  WorkoutListView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutListView: View {
    private let workoutCodes = ["A", "B", "C", "D", "E"]

    var body: some View {
        NavigationStack {
            List(workoutCodes, id: \.self) { code in
                NavigationLink(value: code) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(color(for: code))
                        Text("Workout \(code)")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Progressive Yoga")
            .navigationDestination(for: String.self) { code in
                WorkoutDetailView(workoutCode: code)
            }
        }
    }

    private func color(for code: String) -> Color {
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
