import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ScheduleNextWorkoutSheet: View {
    let workoutName: String
    let workoutCode: String
    @Environment(\.dismiss) private var dismiss

    @State private var scheduledDate = Self.defaultDate()
    @State private var isBusy = false
    @State private var done = false
    @State private var notifDenied = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Date & Time",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                if done {
                    Section {
                        Label("Saved — reminder set 12 h before", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if notifDenied {
                    Section {
                        Label("Notifications blocked — allow in Settings for the 12 h reminder",
                              systemImage: "bell.slash")
                            .foregroundStyle(.orange)
                        #if canImport(UIKit)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        #endif
                    }
                }
            }
            .navigationTitle("Next \(workoutName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isBusy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isBusy {
                        ProgressView()
                    } else {
                        Button("Schedule") { Task { await add() } }
                            .bold()
                            .disabled(done)
                    }
                }
            }
        }
    }

    // MARK: - Action

    private func add() async {
        isBusy = true
        defer { isBusy = false }

        #if canImport(EventKit)
        if !WorkoutCalendar.isAuthorized { await WorkoutCalendar.requestAccess() }
        if WorkoutCalendar.isAuthorized,
           let url = URL(string: "\(WorkoutCalendarBridge.scheme)://upcoming/\(workoutCode)") {
            let end = Calendar.current.date(byAdding: .hour, value: 1, to: scheduledDate) ?? scheduledDate
            WorkoutCalendar.upsert(title: workoutName, start: scheduledDate, end: end,
                                   url: url, notes: nil)
        }
        #endif

        let granted = await WorkoutReminderService.requestAuthorizationIfNeeded()
        if granted {
            await WorkoutReminderService.schedule(name: workoutName, workoutCode: workoutCode,
                                                  at: scheduledDate)
        } else {
            notifDenied = true
        }
        done = true
    }

    // MARK: - Default: 2 days from now at 9:00 AM

    private static func defaultDate() -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.day = (comps.day ?? 0) + 2
        comps.hour = 9
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date().addingTimeInterval(2 * 86400)
    }
}
