//
//  WorkoutDetailView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct WorkoutDetailView: View {
    let workoutCode: String

    @EnvironmentObject private var services: AppServices
    @State private var sessionPresented = false

    @FetchRequest private var families: FetchedResults<CDSkillFamily>

    init(workoutCode: String) {
        self.workoutCode = workoutCode
        _families = FetchRequest<CDSkillFamily>(
            sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)],
            predicate: NSPredicate(format: "series == %@", workoutCode)
        )
    }

    var body: some View {
        List {
            Section("Skill Families") {
                ForEach(families, id: \.self) { family in
                    HStack {
                        Text("\(family.order).")
                            .foregroundStyle(.secondary)
                        Text(family.name)
                    }
                }
            }
        }
        .navigationTitle("Workout \(workoutCode)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start") { sessionPresented = true }
                    .buttonStyle(.borderedProminent)
            }
        }
        .fullScreenCover(isPresented: $sessionPresented) {
            NavigationStack {
                WorkoutSessionView(workoutCode: workoutCode, services: services)
            }
        }
    }
}
