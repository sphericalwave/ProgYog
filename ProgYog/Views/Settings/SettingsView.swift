//
//  SettingsView.swift
//  ProgYog
//

import SwiftUI
import WorkoutSyncKit

struct SettingsView: View {
    @EnvironmentObject private var services: AppServices
    @ObservedObject private var coreData: CoreDataService
    @ObservedObject private var log: ErrorLog
    @AppStorage(HRSettings.ageKey) private var hrAge = 30
    @AppStorage(HRSettings.overrideKey) private var hrMaxOverride = 0
    @AppStorage(WorkoutCalendar.enabledKey) private var calendarEnabled = false
    #if canImport(HealthKit)
    @AppStorage(WorkoutHealth.enabledKey) private var healthEnabled = false
    #endif
    @AppStorage(CompletionSettings.rptMinKey) private var compRptMin = 0
    @AppStorage(CompletionSettings.rpeMaxKey) private var compRpeMax = 0
    @AppStorage(CompletionSettings.rpdMaxKey) private var compRpdMax = 0
    @AppStorage(CompletionSettings.romMinKey) private var compRomMin = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        // Placeholder; environmentObject swaps in real instances.
        self.coreData = CoreDataService(inMemory: true)
        self.log = ErrorLog()
    }

    init(services: AppServices) {
        self.coreData = services.coreData
        self.log = services.errorLog
    }

    var body: some View {
        let coreData = services.coreData
        let log = services.errorLog
        return List {
            Section("Storage") {
                LabeledContent("Last saved", value: coreData.lastSavedAt.map(format) ?? "—")
                if let err = coreData.lastSaveError {
                    LabeledContent("Last save error") { Text(err).foregroundStyle(.red) }
                }
                if coreData.didBackupOnLaunch, let backup = coreData.backupURL {
                    NavigationLink {
                        BackupDetailView(url: backup)
                    } label: {
                        Label("Previous data backed up", systemImage: "tray.full")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section("Heart Rate") {
                NavigationLink {
                    HRMaxSettingsView()
                } label: {
                    LabeledContent(
                        "Max heart rate",
                        value: "\(HRSettings.effectiveMax(age: hrAge, manualOverride: hrMaxOverride)) bpm"
                    )
                }
            }

            Section("Calendar") {
                NavigationLink {
                    CalendarSyncSettingsView()
                } label: {
                    LabeledContent("Workout calendar",
                                   value: calendarEnabled ? "On" : "Off")
                }
                NavigationLink {
                    WorkoutSchedulerSettingsView()
                } label: {
                    Label("Schedule upcoming workouts", systemImage: "calendar.badge.plus")
                }
            }

            #if canImport(HealthKit)
            Section("Health") {
                NavigationLink {
                    HealthSyncSettingsView()
                } label: {
                    LabeledContent("Apple Health", value: healthEnabled ? "On" : "Off")
                }
            }
            #endif

            Section("Completion Scoring") {
                NavigationLink {
                    CompletionSettingsView()
                } label: {
                    LabeledContent(
                        "Qualifying set",
                        value: "RPT≥\(CompletionSettings.rptMin) · "
                             + "RPE≤\(CompletionSettings.rpeMax) · "
                             + "RPD≤\(CompletionSettings.rpdMax) · "
                             + "ROM≥\(CompletionSettings.romMin)%"
                    )
                    .font(.callout)
                }
            }

            Section {
                if log.entries.isEmpty {
                    Text("No errors or events recorded.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(log.entries) { entry in
                        NavigationLink {
                            ErrorDetailView(entry: entry)
                        } label: {
                            row(for: entry)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Log")
                    Spacer()
                    if !log.entries.isEmpty {
                        Button("Clear") { log.clear() }
                            .font(.caption)
                    }
                }
            } footer: {
                Text("All recoverable errors are recorded here. Tap an entry for details. Nothing is sent off-device.")
                    .font(.caption2)
            }

            #if DEBUG
            Section("Developer") {
                Button("Preview Onboarding") {
                    hasSeenOnboarding = false
                }
            }
            #endif

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: appBuild)
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.accentColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .onAppear { log.markRead() }
    }

    @ViewBuilder
    private func row(for entry: ErrorLog.Entry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: entry.level.symbolName)
                .foregroundStyle(color(for: entry.level))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.message).font(.callout)
                HStack(spacing: 6) {
                    Text(entry.source).font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.secondary)
                    Text(format(entry.timestamp)).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func color(for level: ErrorLog.Entry.Level) -> Color {
        switch level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    private func format(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .standard)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

private struct BackupDetailView: View {
    let url: URL
    var body: some View {
        List {
            Section("Backup") {
                LabeledContent("File", value: url.lastPathComponent)
                LabeledContent("Folder", value: url.deletingLastPathComponent().path)
            }
            Section {
                Text("The previous Core Data store could not be loaded and was renamed to preserve its contents. If you want to recover it, the file above is intact on disk.")
                    .font(.callout)
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Backup")
    }
}

private struct HRMaxSettingsView: View {
    @AppStorage(HRSettings.ageKey) private var age = 30
    @AppStorage(HRSettings.overrideKey) private var manualOverride = 0

    private var formulaMax: Int { max(220 - age, 1) }
    private var isOverridden: Bool { manualOverride > 0 }

    var body: some View {
        List {
            Section("Age") {
                Stepper(value: $age, in: 10...100) {
                    LabeledContent("Age", value: "\(age)")
                }
            }

            Section {
                LabeledContent("220 − age", value: "\(formulaMax) bpm")
                Toggle("Override max HR", isOn: Binding(
                    get: { isOverridden },
                    set: { manualOverride = $0 ? formulaMax : 0 }
                ))
                if isOverridden {
                    Stepper(value: $manualOverride, in: 100...230) {
                        LabeledContent("Max HR", value: "\(manualOverride) bpm")
                    }
                }
            } footer: {
                Text("Defaults to the 220 − age estimate. Override it with your measured max heart rate. Used to show each set's heart rate as a percentage of max.")
            }

            Section("Effective") {
                LabeledContent(
                    "Max heart rate",
                    value: "\(HRSettings.effectiveMax(age: age, manualOverride: manualOverride)) bpm"
                )
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Max Heart Rate")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct CalendarSyncSettingsView: View {
    @Environment(\.managedObjectContext) private var moc
    @AppStorage(WorkoutCalendar.enabledKey) private var enabled = false
    @AppStorage(WorkoutCalendar.colorKey) private var colorHex = WorkoutCalendar.defaultColorHex
    @State private var denied = false
    @State private var confirmRemoveAll = false

    private var color: Binding<Color> {
        Binding(
            get: { Color(hex: colorHex) ?? .orange },
            set: { newValue in
                let hex = newValue.hexString
                colorHex = hex
                WorkoutCalendar.setColor(hex: hex)
            }
        )
    }

    var body: some View {
        List {
            Section {
                Toggle("Show workouts in Calendar", isOn: $enabled)
                    .onChange(of: enabled) { _, on in
                        if on {
                            Task {
                                let ok = await WorkoutCalendar.requestAccess()
                                if ok {
                                    denied = false
                                    WorkoutCalendarBridge.syncAll(moc: moc)
                                } else {
                                    enabled = false
                                    denied = true
                                }
                            }
                        } else {
                            WorkoutCalendar.disable()
                        }
                    }
                if denied {
                    Text("Calendar access denied. Enable it in Settings › Privacy › Calendars.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } footer: {
                Text("Mirrors each completed workout into a \"Workout\" calendar as a timed event. Tap an event to open it in the app.")
            }

            if enabled {
                Section("Appearance") {
                    ColorPicker("Calendar color", selection: color, supportsOpacity: false)
                }

                Section {
                    Button("Add all past workouts") {
                        WorkoutCalendarBridge.syncAll(moc: moc)
                    }
                    Button("Remove all workout events", role: .destructive) {
                        confirmRemoveAll = true
                    }
                } footer: {
                    Text("Add backfills every completed workout. Remove clears the events but keeps the calendar.")
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Workout Calendar")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .confirmationDialog(
            "Remove all workout events?",
            isPresented: $confirmRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) {
                WorkoutCalendarBridge.removeAll()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

#if canImport(HealthKit)
private struct HealthSyncSettingsView: View {
    @Environment(\.managedObjectContext) private var moc
    @AppStorage(WorkoutHealth.enabledKey) private var enabled = false
    @AppStorage(WorkoutHealth.lastSyncedAtKey) private var lastSyncedTimestamp: Double = 0
    @State private var denied = false
    @State private var isSyncing = false
    @State private var confirmRemoveAll = false

    private var lastSyncedAt: Date? {
        lastSyncedTimestamp > 0 ? Date(timeIntervalSince1970: lastSyncedTimestamp) : nil
    }

    var body: some View {
        List {
            Section {
                Toggle("Show workouts in Health", isOn: $enabled)
                    .onChange(of: enabled) { _, on in
                        if on {
                            Task {
                                let ok = await WorkoutHealth.requestAccess()
                                if ok {
                                    denied = false
                                    isSyncing = true
                                    await WorkoutHealthBridge.syncAllAsync(moc: moc)
                                    isSyncing = false
                                } else {
                                    enabled = false
                                    denied = true
                                }
                            }
                        }
                    }
                if denied {
                    Text("Health access denied. Enable it in Settings › Privacy & Security › Health › ProgYog.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } footer: {
                Text("Logs each completed workout into Apple Health as a Yoga session. One entry per workout day.")
            }

            if enabled {
                Section {
                    Button {
                        guard !isSyncing else { return }
                        isSyncing = true
                        Task {
                            await WorkoutHealthBridge.syncAllAsync(moc: moc)
                            isSyncing = false
                        }
                    } label: {
                        HStack {
                            Text(isSyncing ? "Syncing…" : "Add all past workouts")
                            if isSyncing {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSyncing)

                    if let date = lastSyncedAt {
                        LabeledContent("Last synced",
                                       value: date.formatted(date: .abbreviated, time: .standard))
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }

                    Button("Remove all workout data", role: .destructive) {
                        confirmRemoveAll = true
                    }
                    .disabled(isSyncing)
                } footer: {
                    Text("Add backfills every completed workout. Existing entries are updated in place — no duplicates. Remove deletes all workout data written by this app from Health.")
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Apple Health")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .confirmationDialog(
            "Remove all workout data from Health?",
            isPresented: $confirmRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) {
                WorkoutHealthBridge.removeAll()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
#endif

struct CompletionSettingsView: View {
    // Bound directly to @AppStorage so the Stepper +/- triggers a real
    // write + SwiftUI re-render. Default = the constant, so a fresh user
    // sees the real bar (not 0).
    @AppStorage(CompletionSettings.rptMinKey) private var rptMin: Int = Int(CompletionSettings.defaultRptMin)
    @AppStorage(CompletionSettings.rpeMaxKey) private var rpeMax: Int = Int(CompletionSettings.defaultRpeMax)
    @AppStorage(CompletionSettings.rpdMaxKey) private var rpdMax: Int = Int(CompletionSettings.defaultRpdMax)
    @AppStorage(CompletionSettings.romMinKey) private var romMin: Int = Int(CompletionSettings.defaultRomMin)

    var body: some View {
        List {
            Section {
                Stepper(value: $romMin, in: 5...100, step: 5) {
                    LabeledContent("ROM target ≥", value: "\(romMin)%")
                }
            } header: {
                Text("Scoring")
            } footer: {
                Text("Two scores, one target:\n\n"
                   + "Set score — clamp(ROM ÷ target, 0–100%). Depth-independent. Full range at any level = 100%.\n\n"
                   + "Workout score — (depth − 1 + ROM fraction) ÷ max depth × 100. Reaches 100% only at the highest skill level with full ROM. Tracks how far through the progression you are.")
            }

            Section {
                Stepper(value: $rptMin, in: 1...10) {
                    LabeledContent("Technique (RPT) ≥", value: "\(rptMin)")
                }
                Stepper(value: $rpeMax, in: 1...10) {
                    LabeledContent("Effort (RPE) ≤", value: "\(rpeMax)")
                }
                Stepper(value: $rpdMax, in: 1...10) {
                    LabeledContent("Discomfort (RPD) ≤", value: "\(rpdMax)")
                }
            } header: {
                Text("Advisory thresholds")
            } footer: {
                Text("RPT, RPE, and RPD are logged and visible in history but don't change your score. They're reference points to flag sets that felt off.")
            }

            Section {
                LabeledContent("ROM target", value: "\(CompletionSettings.defaultRomMin)%")
                LabeledContent("RPT ≥", value: "\(CompletionSettings.defaultRptMin)")
                LabeledContent("RPE ≤", value: "\(CompletionSettings.defaultRpeMax)")
                LabeledContent("RPD ≤", value: "\(CompletionSettings.defaultRpdMax)")
                Button("Reset to defaults") {
                    rptMin = Int(CompletionSettings.defaultRptMin)
                    rpeMax = Int(CompletionSettings.defaultRpeMax)
                    rpdMax = Int(CompletionSettings.defaultRpdMax)
                    romMin = Int(CompletionSettings.defaultRomMin)
                }
            } header: {
                Text("Defaults")
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Completion Scoring")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct WorkoutCodeItem: Identifiable {
    let code: String
    var id: String { code }
}

private struct WorkoutSchedulerSettingsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "endedAt", ascending: false)],
        predicate: NSPredicate(format: "endedAt != nil")
    ) private var completedSessions: FetchedResults<Session>

    @State private var selectedCode: WorkoutCodeItem?

    private static let sequence = ["A", "B", "C", "D", "E"]

    private var lastSession: Session? { completedSessions.first }

    private var nextCodes: [String] {
        let startIdx: Int
        if let code = lastSession?.workoutCode,
           let idx = Self.sequence.firstIndex(of: code) {
            startIdx = (idx + 1) % Self.sequence.count
        } else {
            startIdx = 0
        }
        return (0..<Self.sequence.count).map {
            Self.sequence[(startIdx + $0) % Self.sequence.count]
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(Array(nextCodes.enumerated()), id: \.element) { offset, code in
                    Button {
                        selectedCode = WorkoutCodeItem(code: code)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(WorkoutLabel.display(forCode: code))
                                    .foregroundStyle(.primary)
                                if offset == 0 {
                                    Text("Next up")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            } header: {
                if let last = lastSession, let endedAt = last.endedAt {
                    Text("Last: \(WorkoutLabel.display(for: last)) · \(endedAt.formatted(date: .abbreviated, time: .omitted))")
                } else {
                    Text("No workouts completed yet")
                }
            } footer: {
                Text("Tap a workout to add it to your calendar and set a reminder.")
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Schedule Workouts")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if canImport(EventKit)
        .sheet(item: $selectedCode) { item in
            ScheduleNextWorkoutSheet(
                workoutName: WorkoutLabel.display(forCode: item.code),
                workoutCode: item.code
            )
        }
        #endif
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView(services: PreviewSupport.services)
    }
    .environmentObject(PreviewSupport.services)
}
#endif
