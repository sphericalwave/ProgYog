import SwiftUI

struct MacRootView: View {
    @AppStorage("macSelectedSidebar") private var selection: String = "workouts"
    @EnvironmentObject var services: AppServices

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Workouts", systemImage: "figure.yoga").tag("workouts")
                Label("Dashboard", systemImage: "chart.bar.xaxis").tag("dashboard")
                Label("History", systemImage: "clock.arrow.circlepath").tag("history")
                Label("Settings", systemImage: "gear").tag("settings")
            }
            .navigationTitle("ProgYog")
        } detail: {
            switch selection {
            case "dashboard":
                NavigationStack { DashboardView() }
            case "history":
                NavigationStack { SessionHistoryView() }
            case "settings":
                NavigationStack { SettingsView() }
            default:
                WorkoutListView()
            }
        }
    }
}
