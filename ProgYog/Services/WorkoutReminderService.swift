import UserNotifications

@MainActor
enum WorkoutReminderService {

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default: return false
        }
    }

    /// Schedule a notification 12 hours before `date`. No-ops if that fire time is already past.
    static func schedule(name: String, workoutCode: String, at date: Date) async {
        guard let fireDate = Calendar.current.date(byAdding: .hour, value: -12, to: date),
              fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Workout in 12 Hours"
        content.body = name
        content.sound = .default
        content.userInfo = ["workoutCode": workoutCode]

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: notifID(workoutCode, date),
                                            content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel(workoutCode: String, at date: Date) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notifID(workoutCode, date)])
    }

    private static func notifID(_ code: String, _ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMddHHmm"
        return "workout-reminder-\(code)-\(f.string(from: date))"
    }
}
