//
//  RootView.swift
//  Groundwerk
//

import SwiftUI
import SwKeyboard
import CoreData

struct RootView: View {
    @EnvironmentObject var services: AppServices
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("rootSelectedTab") private var selectedTab = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var historyPath: [NSManagedObjectID] = []
    @State private var pendingSessionID: UUID?

    private let historyTab = 3

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutListView()
                .tabItem { Label("Workouts", systemImage: "figure.yoga") }
                .tag(0)

            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "chart.bar.xaxis") }
            .tag(1)

            NavigationStack(path: $historyPath) {
                SessionHistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(historyTab)

            NavigationStack {
                PostureCameraView()
            }
            .tabItem { Label("Vision", systemImage: "person.fill.viewfinder") }
            .tag(5)

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
        .doneKeyboardToolbar()
        .onShake {
            _ = services.undo.undoLast()
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { if !$0 { hasSeenOnboarding = true } }
        )) {
            OnboardingView()
        }
        .overlay(alignment: .top) {
            UndoToast()
                .environmentObject(services)
        }
        .onOpenURL { url in
            if let id = WorkoutCalendarBridge.sessionID(from: url) {
                pendingSessionID = id
                routePendingSession()
            } else if url.scheme == WorkoutCalendarBridge.scheme, url.host == "upcoming" {
                selectedTab = 0
            }
        }
        .task {
            // First-launch sync — scenePhase onChange only fires on a
            // change to .active, so a fresh launch wouldn't catch
            // calendar title drift (e.g. after a rename patch).
            WorkoutCalendarBridge.syncAll(moc: services.coreData.moc)
            WorkoutHealthBridge.syncAll(moc: services.coreData.moc)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            WorkoutCalendarBridge.syncAll(moc: services.coreData.moc)
            WorkoutHealthBridge.syncAll(moc: services.coreData.moc)
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

