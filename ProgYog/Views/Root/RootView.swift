//
//  RootView.swift
//  ProgYog
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var services: AppServices

    var body: some View {
        TabView {
            WorkoutListView()
                .tabItem { Label("Workouts", systemImage: "figure.yoga") }

            NavigationStack {
                SkillFamilyListView()
            }
            .tabItem { Label("Families", systemImage: "list.bullet") }

            NavigationStack {
                AbsSkillListView()
            }
            .tabItem { Label("Skills", systemImage: "square.grid.2x2") }

            NavigationStack {
                SessionHistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            NavigationStack {
                SettingsView(services: services)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .badge(services.errorLog.unreadCount)
        }
        .environment(\.managedObjectContext, services.coreData.moc)
    }
}

#if DEBUG
#Preview {
    RootView()
        .environmentObject(PreviewSupport.services)
}
#endif
