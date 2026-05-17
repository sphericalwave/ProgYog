//
//  SettingsView.swift
//  ProgYog
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var services: AppServices
    @ObservedObject private var coreData: CoreDataService
    @ObservedObject private var log: ErrorLog
    @AppStorage(HRSettings.ageKey) private var hrAge = 30
    @AppStorage(HRSettings.overrideKey) private var hrMaxOverride = 0

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

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: appBuild)
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Settings")
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
        .navigationBarTitleDisplayMode(.inline)
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
