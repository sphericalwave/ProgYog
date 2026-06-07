//
//  ScheduleNextWorkoutSheet.swift
//  ProgYog
//

import SwiftUI

#if canImport(EventKit)
import EventKit

struct ScheduleNextWorkoutSheet: View {
    let workoutName: String
    let workoutCode: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: AppServices
    
    @State private var selectedDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var duration: TimeInterval = 3600 // 1 hour default
    @State private var reminderEnabled = true
    @State private var reminderOffset: TimeInterval = -43200 // 12 hours before
    @State private var scheduled = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date & Time", selection: $selectedDate, in: Date()...)
                        .datePickerStyle(.graphical)
                }
                
                Section("Duration") {
                    Picker("Duration", selection: $duration) {
                        Text("30 min").tag(TimeInterval(1800))
                        Text("45 min").tag(TimeInterval(2700))
                        Text("1 hour").tag(TimeInterval(3600))
                        Text("1.5 hours").tag(TimeInterval(5400))
                        Text("2 hours").tag(TimeInterval(7200))
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Toggle("Reminder", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        Picker("Remind me", selection: $reminderOffset) {
                            Text("At time of event").tag(TimeInterval(0))
                            Text("5 min before").tag(TimeInterval(-300))
                            Text("15 min before").tag(TimeInterval(-900))
                            Text("30 min before").tag(TimeInterval(-1800))
                            Text("1 hour before").tag(TimeInterval(-3600))
                            Text("12 hours before").tag(TimeInterval(-43200))
                            Text("1 day before").tag(TimeInterval(-86400))
                        }
                    }
                } header: {
                    Text("Reminder")
                }
                
                if scheduled {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Added to calendar")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Schedule Next Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schedule") {
                        scheduleWorkout()
                    }
                    .bold()
                    .disabled(scheduled)
                }
            }
        }
    }
    
    private func scheduleWorkout() {
        guard WorkoutCalendar.isAuthorized else { return }
        
        let endDate = selectedDate.addingTimeInterval(duration)
        let sessionID = UUID()
        
        guard let url = URL(string: "\(WorkoutCalendarBridge.scheme)://session/\(sessionID.uuidString)") else {
            return
        }
        
        var notes = "Scheduled workout"
        if reminderEnabled {
            let reminderText = reminderOffset == 0 ? "at time of event" : formatReminderOffset(reminderOffset)
            notes += "\nReminder: \(reminderText)"
        }
        
        let success = WorkoutCalendar.upsert(
            title: workoutName,
            start: selectedDate,
            end: endDate,
            url: url,
            notes: notes
        )
        
        if success {
            withAnimation {
                scheduled = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            }
        }
    }
    
    private func formatReminderOffset(_ offset: TimeInterval) -> String {
        let absOffset = abs(offset)
        if absOffset >= 86400 {
            return "1 day before"
        } else if absOffset >= 43200 {
            return "12 hours before"
        } else if absOffset >= 3600 {
            return "1 hour before"
        } else if absOffset >= 1800 {
            return "30 minutes before"
        } else if absOffset >= 900 {
            return "15 minutes before"
        } else if absOffset >= 300 {
            return "5 minutes before"
        }
        return "at time of event"
    }
}

#if DEBUG
private struct ScheduleNextWorkoutSheetPreviewHost: View {
    @State private var presented = true
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .sheet(isPresented: $presented) {
                ScheduleNextWorkoutSheet(
                    workoutName: "Full Body Workout A",
                    workoutCode: "FBW-A"
                )
                .environmentObject(PreviewSupport.services)
            }
    }
}

#Preview("Modal") {
    ScheduleNextWorkoutSheetPreviewHost()
}
#endif
#endif
