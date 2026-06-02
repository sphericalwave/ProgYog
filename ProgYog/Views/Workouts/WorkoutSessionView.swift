//
//  WorkoutSessionView.swift
//  ProgYog
//

import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var vm: WorkoutSessionViewModel
    @EnvironmentObject private var services: AppServices
    @Environment(\.dismiss) private var dismiss
    @State private var summaryPresented = false
    @State private var addVariantKind: AddVariantKind?
    @State private var poseCheckPresented = false

    private enum AddVariantKind: Identifiable {
        case easier, harder
        var id: Self { self }
    }

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
        sessionContent(fill: true)
            .padding()
            .navigationTitle(WorkoutLabel.display(forCode: vm.workoutCode))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                if vm.phase == .finished { summaryPresented = true }
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .onChange(of: vm.phase) { _, new in
                if new == .finished { summaryPresented = true }
            }
            .navigationDestination(isPresented: $summaryPresented) {
                WorkoutSummaryView(session: vm.session, onDone: { dismiss() })
            }
            .toolbar {
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
        .sheet(isPresented: Binding(
            get: { vm.phase == .logging },
            set: { presented in
                if !presented, vm.phase == .logging { vm.phase = .idle }
            }
        )) {
            if let skill = vm.currentSkill {
                SetLogSheet(
                    skill: skill,
                    suggestion: vm.suggestion,
                    currentSession: vm.session,
                    liveHRStats: vm.currentSetHRStats,
                    isFinalRound: vm.isFinalRound,
                    onSave: { vm.recordLog($0) },
                    onCancel: { vm.phase = .idle }
                )
            }
        }
        .sheet(item: $addVariantKind) { kind in
            if let fam = vm.currentFamily {
                AddVariantSheet(
                    family: fam,
                    currentSkill: vm.currentSkill,
                    defaultInsertBefore: kind == .easier ? vm.currentSkill : vm.nextSkill,
                    onSave: { name, instructions, photoData, insertBefore in
                        vm.addVariant(name: name, instructions: instructions,
                                      photoData: photoData, insertBefore: insertBefore)
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $poseCheckPresented) {
            NavigationStack { PostureCameraView() }
        }
    }

    /// Shared phase content. `fill` keeps the idle/running/logging layout
    /// (instructions card / Spacer expand to pin the timer & buttons); the
    /// finished phase passes `false` so it sizes naturally inside a ScrollView.
    @ViewBuilder
    private func sessionContent(fill: Bool) -> some View {
        VStack(spacing: 16) {
            nameHeader

            if let skill = vm.currentSkill {
                if !skill.posterAssetNames.isEmpty {
                    SkillPosterGallery(names: skill.posterAssetNames)
                        .frame(maxHeight: 220)
                } else if let data = skill.customPhotoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if vm.currentSkill != nil {
                levelControls
            }

            if let skill = vm.currentSkill, !skill.instructions.isEmpty {
                instructionsCard(for: skill)
                    .frame(maxHeight: fill ? .infinity : nil)
            } else if fill {
                Spacer()
            }

            phaseContent
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
        case .logging, .finished:
            Color.clear.frame(height: 1) // sheet / summary push handles it
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

            if vm.currentFamily != nil {
                HStack(spacing: 12) {
                    Button("Add Easier Variant") { addVariantKind = .easier }
                        .frame(maxWidth: .infinity)
                    Button("Add Harder Variant") { addVariantKind = .harder }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Button { poseCheckPresented = true } label: {
                Label("Posture Check", systemImage: "figure.stand")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }

    private var runningView: some View {
        VStack(spacing: 16) {
            Text(timeString(vm.secondsRemaining))
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            ProgressView(value: Double(vm.secondsRemaining), total: Double(vm.effectiveDuration))
                .progressViewStyle(.linear)
            Button(action: vm.skipToLog) {
                Label("Skip to Log", systemImage: "forward.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
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
