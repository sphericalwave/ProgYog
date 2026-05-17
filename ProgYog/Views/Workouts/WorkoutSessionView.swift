//
//  WorkoutSessionView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var vm: WorkoutSessionViewModel
    @EnvironmentObject private var services: AppServices
    @Environment(\.dismiss) private var dismiss

    init(workoutCode: String, services: AppServices, resuming existing: Session? = nil) {
        _vm = StateObject(wrappedValue: WorkoutSessionViewModel(workoutCode: workoutCode, services: services, resuming: existing))
    }

    #if DEBUG
    init(previewPhase: WorkoutSessionViewModel.Phase, workoutCode: String, services: AppServices) {
        let model = WorkoutSessionViewModel(workoutCode: workoutCode, services: services)
        model.phase = previewPhase
        _vm = StateObject(wrappedValue: model)
    }
    #endif

    var body: some View {
        VStack(spacing: 16) {
            nameHeader

            if let skill = vm.currentSkill, !skill.posterAssetNames.isEmpty {
                SkillPosterGallery(names: skill.posterAssetNames)
                    .frame(maxHeight: 220)
            }

            if vm.currentSkill != nil {
                levelControls
            }

            if let skill = vm.currentSkill, !skill.instructions.isEmpty {
                instructionsCard(for: skill)
                    .frame(maxHeight: .infinity)
            } else {
                Spacer()
            }

            phaseContent
        }
        .padding()
        .navigationTitle("Workout \(vm.workoutCode)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .toolbar {
            if vm.phase == .finished {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        WorkoutSummaryView(session: vm.session)
                    } label: {
                        Text("Done").bold()
                    }
                }
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        vm.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HRPill(heartRate: services.heartRate)
                }
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
                    currentSession: vm.session,
                    liveHRStats: vm.currentSetHRStats,
                    onSave: { vm.recordLog($0) }
                )
                .interactiveDismissDisabled()
            }
        }
    }

    private var nameHeader: some View {
        VStack(spacing: 4) {
            Text(vm.headerLine).font(.subheadline).foregroundStyle(.secondary)
            if let skill = vm.currentSkill {
                Text(skill.name).font(.title2).bold()
                Text("\(skill.family) - Level \(skill.depth)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var levelControls: some View {
        HStack(spacing: 12) {
            Button(action: vm.regressCurrentSkill) {
                Label("Regress", systemImage: "arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!vm.canRegressCurrentSkill)

            Button(action: vm.progressCurrentSkill) {
                Label("Progress", systemImage: "arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!vm.canProgressCurrentSkill)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    private func instructionsCard(for skill: CDAbsSkill) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Instructions")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    if services.audio.isSpeaking {
                        services.audio.stopSpeaking()
                    } else {
                        services.audio.speak(skill.instructions)
                    }
                } label: {
                    Image(systemName: services.audio.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
            }
            ScrollView {
                Text(skill.instructions)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
    }

    @ViewBuilder
    private var phaseContent: some View {
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
    }

    private var idleView: some View {
        VStack(spacing: 16) {

            Button(action: vm.startSet) {
                Text(vm.familyIdx == 0 && vm.roundIdx == 0 ? "Start Workout" : "Start Set")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: vm.skipToLog) {
                Text("Log Without Timer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
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
            Button(action: vm.skipToLog) {
                Label("Skip to Log", systemImage: "forward.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var finishedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Workout complete").font(.title2.bold())

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session notes").font(.caption).foregroundStyle(.secondary)
                    TextField(
                        "How did it feel?",
                        text: Binding(
                            get: { vm.session.notes ?? "" },
                            set: { vm.setSessionNotes($0) }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: .infinity)

                HRPill(heartRate: services.heartRate)
            }
        }
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60
        let r = s % 60
        return String(format: "%01d:%02d", m, r)
    }
}

private struct HRPill: View {
    @ObservedObject var heartRate: HeartRateService
    @State private var showSheet = false

    var body: some View {
        Button { showSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                if let bpm = heartRate.bpm { Text("\(bpm) bpm").monospacedDigit() }
                else { Text(heartRate.state.label).foregroundStyle(.secondary) }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .sheet(isPresented: $showSheet) {
            HRConnectSheet(heartRate: heartRate)
        }
    }
}

#if DEBUG
@MainActor
private func workoutSessionPreview(_ phase: WorkoutSessionViewModel.Phase) -> some View {
    NavigationStack {
        WorkoutSessionView(previewPhase: phase, workoutCode: "A", services: PreviewSupport.services)
    }
    .keyboardDoneToolbar()
    .environmentObject(PreviewSupport.services)
    .environment(\.managedObjectContext, PreviewSupport.services.coreData.moc)
}

#Preview("Idle") { workoutSessionPreview(.idle) }
#Preview("Running") { workoutSessionPreview(.running) }
#Preview("Logging") { workoutSessionPreview(.logging) }
#Preview("Finished") { workoutSessionPreview(.finished) }
#endif

private struct HRConnectSheet: View {
    @ObservedObject var heartRate: HeartRateService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    Text(heartRate.state.label)
                        .foregroundStyle(.secondary)
                }
                Section("Discovered") {
                    if heartRate.discovered.isEmpty {
                        Text("Make sure your HR strap is on and not connected to another app. Then tap Scan.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(heartRate.discovered, id: \.identifier) { p in
                        Button {
                            heartRate.connect(p)
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
            .onAppear { heartRate.startScan() }
            .onDisappear { heartRate.stopScan() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Scan") { heartRate.startScan() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
