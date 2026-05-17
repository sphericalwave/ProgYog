//
//  RootView.swift
//  ProgYog
//

import SwiftUI
import CoreData

struct RootView: View {
    @EnvironmentObject var services: AppServices
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab = 0
    @State private var historyPath: [NSManagedObjectID] = []
    @State private var pendingSessionID: UUID?

    private let historyTab = 3

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutListView()
                .tabItem { Label("Workouts", systemImage: "figure.yoga") }
                .tag(0)

            NavigationStack {
                SkillFamilyListView()
            }
            .tabItem { Label("Families", systemImage: "list.bullet") }
            .tag(1)

            NavigationStack {
                AbsSkillListView()
            }
            .tabItem { Label("Skills", systemImage: "square.grid.2x2") }
            .tag(2)

            NavigationStack(path: $historyPath) {
                SessionHistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(historyTab)

            NavigationStack {
                SettingsView(services: services)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .badge(services.errorLog.unreadCount)
            .tag(4)
        }
        .environment(\.managedObjectContext, services.coreData.moc)
        .keyboardDoneToolbar()
        .onOpenURL { url in
            if let id = WorkoutCalendarBridge.sessionID(from: url) {
                pendingSessionID = id
                routePendingSession()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            WorkoutCalendarBridge.syncAll(moc: services.coreData.moc)
            routePendingSession()
        }
    }

    /// Resolve a deep-linked session UUID to its object and push it in the
    /// History stack. Cold-launch safe: retries on scene-active until the
    /// store can resolve it.
    private func routePendingSession() {
        guard let id = pendingSessionID else { return }
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fr.fetchLimit = 1
        if let session = try? services.coreData.moc.fetch(fr).first {
            selectedTab = historyTab
            historyPath = [session.objectID]
            pendingSessionID = nil
        }
    }
}

#if DEBUG
#Preview {
    RootView()
        .environmentObject(PreviewSupport.services)
}
#endif
