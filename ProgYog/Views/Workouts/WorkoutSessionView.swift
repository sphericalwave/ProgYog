//
//  WorkoutSessionView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var vm: WorkoutSessionViewModel
    @EnvironmentObject private var services: AppServices
    @Environment(\.dismiss) private var dismiss

    init(workoutCode: String, services: AppServices) {
        _vm = StateObject(wrappedValue: WorkoutSessionViewModel(workoutCode: workoutCode, services: services))
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            Spacer()

            switch vm.phase {
            case .idle:
                idleView
            case .running:
                runningView
            case .logging:
                Color.clear.frame(height: 1) // sheet handles it
            case .finished:
                finishedView
            }

            Spacer()

            HRPill(bpm: services.heartRate.bpm, state: services.heartRate.state)
        }
        .padding()
        .navigationTitle("Workout \(vm.workoutCode)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    vm.cancel()
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("HR") { /* connect sheet hooked in HRPill */ }
                    .opacity(0)
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.phase == .logging },
            set: { _ in }
        )) {
            if let skill = vm.currentSkill {
                SetLogSheet(
                    skill: skill,
                    suggestion: vm.suggestion,
                    onSave: { reps, rpt, rpe, rpd, decision in
                        vm.recordLog(reps: reps, rpt: rpt, rpe: rpe, rpd: rpd, decision: decision)
                    }
                )
                .interactiveDismissDisabled()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(vm.headerLine).font(.subheadline).foregroundStyle(.secondary)
            if let skill = vm.currentSkill {
                Text(skill.name).font(.title2).bold()
                Text("Depth \(skill.depth)").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Button(action: vm.startSet) {
                Text(vm.familyIdx == 0 && vm.roundIdx == 0 ? "Start Workout" : "Start Set")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var runningView: some View {
        VStack(spacing: 16) {
            Text(timeString(vm.secondsRemaining))
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            ProgressView(value: Double(vm.secondsRemaining), total: Double(vm.setDurationSec))
                .progressViewStyle(.linear)
        }
    }

    private var finishedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Workout complete").font(.title2.bold())
            NavigationLink {
                WorkoutSummaryView(session: vm.session)
            } label: {
                Text("View Summary")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%01d:%02d", m, r)
    }
}

private struct HRPill: View {
    let bpm: Int?
    let state: HeartRateService.ConnectionState
    @EnvironmentObject var services: AppServices
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                if let bpm { Text("\(bpm) bpm").monospacedDigit() }
                else { Text(label).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .sheet(isPresented: $showSheet) {
            HRConnectSheet().environmentObject(services)
        }
    }

    private var label: String {
        switch state {
        case .idle: return "Connect HR"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .connected(let name): return name
        case .disconnected: return "Reconnect"
        }
    }
}

private struct HRConnectSheet: View {
    @EnvironmentObject var services: AppServices
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Discovered") {
                    if services.heartRate.discovered.isEmpty {
                        Text("Press Scan to look for nearby HR monitors.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(services.heartRate.discovered, id: \.identifier) { p in
                        Button {
                            services.heartRate.connect(p)
                            dismiss()
                        } label: {
                            HStack {
                                Text(p.name ?? "Unknown")
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Heart Rate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Scan") { services.heartRate.startScan() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
