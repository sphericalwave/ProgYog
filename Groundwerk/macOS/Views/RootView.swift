//
//  RootView.swift
//  Groundwerk (macOS)
//
//  Sidebar + detail split. No onboarding, Vision (camera) or shake-to-undo
//  on the Mac: undo of the last delete lives in Edit ▸ Undo Last Delete (⌥⌘Z).
//

import SwiftUI
import CoreData
import WorkoutSyncKit

struct RootView: View {
    enum Section: String, CaseIterable, Identifiable {
        case workouts, dashboard, history, settings
        var id: String { rawValue }

        var title: String {
            switch self {
            case .workouts: "Workouts"
            case .dashboard: "Dashboard"
            case .history: "History"
            case .settings: "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .workouts: "figure.yoga"
            case .dashboard: "chart.bar.xaxis"
            case .history: "clock.arrow.circlepath"
            case .settings: "gear"
            }
        }
    }

    @EnvironmentObject var services: AppServices
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("macSelectedSidebar") private var selection: Section = .workouts
    @State private var historyPath: [NSManagedObjectID] = []
    @State private var pendingSessionID: UUID?

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: Binding(
                get: { selection },
                set: { if let new = $0 { selection = new } }
            )) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("groundWerk")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selection {
            case .workouts:
                WorkoutListView()
            case .dashboard:
                NavigationStack { DashboardView() }
            case .history:
                NavigationStack(path: $historyPath) { SessionHistoryView() }
            case .settings:
                NavigationStack { SettingsView() }
            }
        }
        .environment(\.managedObjectContext, services.coreData.moc)
        .overlay(alignment: .top) {
            UndoToast()
                .environmentObject(services)
        }
        .onOpenURL { url in
            if let id = WorkoutCalendarBridge.sessionID(from: url) {
                pendingSessionID = id
                routePendingSession()
            } else if url.scheme == WorkoutCalendarBridge.scheme, url.host == "upcoming" {
                selection = .workouts
            }
        }
        .task {
            WorkoutCalendarBridge.syncAll(moc: services.coreData.moc)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            WorkoutCalendarBridge.syncAll(moc: services.coreData.moc)
            routePendingSession()
        }
    }

    /// Resolve a deep-linked session UUID and show it in History.
    private func routePendingSession() {
        guard let id = pendingSessionID else { return }
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fr.fetchLimit = 1
        if let session = try? services.coreData.moc.fetch(fr).first {
            selection = .history
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
