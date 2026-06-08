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
    @State private var addVariantPresented = false
    @State private var isometricMode: Bool = false
    @State private var editingInstructions = false

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
        List {
            if let skill = vm.currentSkill {
                Section {
                    skillRows(for: skill)
                } header: {
                    skillImageHeader(for: skill)
                }
            }

            if vm.phase == .running {
                Section { runningView.padding(.vertical, 8) }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .listStyle(.insetGrouped)
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
                    Button {
                        vm.cancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(WorkoutLabel.display(forCode: vm.workoutCode))
                            .font(.headline)
                        Text("Round \(vm.roundIdx + 1) of \(vm.totalRounds)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HRPill(heartRate: services.heartRate)
                }
            }
            .safeAreaInset(edge: .bottom) { idleBottomBar }
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
                    initialIsometric: isometricMode,
                    onSave: { vm.recordLog($0) },
                    onCancel: { vm.phase = .idle }
                )
            }
        }
        .sheet(isPresented: $editingInstructions) {
            if let skill = vm.currentSkill {
                InstructionsEditSheet(initialText: skill.instructions) { newText in
                    skill.instructions = newText
                    services.coreData.save()
                    vm.objectWillChange.send()
                }
            }
        }
        .sheet(isPresented: $addVariantPresented) {
            if let fam = vm.currentFamily {
                AddVariantSheet(
                    family: fam,
                    currentSkill: vm.currentSkill,
                    defaultInsertBefore: nil,
                    onSave: { name, instructions, photoData, insertBefore in
                        vm.addVariant(name: name, instructions: instructions,
                                      photoData: photoData, insertBefore: insertBefore)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func skillImageHeader(for skill: CDAbsSkill) -> some View {
        if !skill.posterAssetNames.isEmpty {
            SkillPosterGallery(names: skill.posterAssetNames, contentMode: .fill, cornerRadius: 12)
                .frame(maxWidth: .infinity, maxHeight: 220)
                .padding(.bottom, 20)
                .listRowInsets(EdgeInsets())
        } else if let data = skill.customPhotoData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 220)
                .padding(.bottom, 20)
                .listRowInsets(EdgeInsets())
        }
    }

    @ViewBuilder
    private func skillRows(for skill: CDAbsSkill) -> some View {
        HStack {
            Text(skill.name).font(.title2.bold())
            Spacer()
            Stepper(
                onIncrement: vm.canProgressCurrentSkill ? { vm.progressCurrentSkill() } : nil,
                onDecrement: vm.canRegressCurrentSkill ? { vm.regressCurrentSkill() } : nil
            ) {
                Text("Level \(skill.depth)")
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            .fixedSize()
        }
        .padding(.top, 16)

        HStack(spacing: 8) {
            Text(skill.family).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button { addVariantPresented = true } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.borderless)
            .opacity(vm.currentFamily != nil ? 1 : 0)
        }

        HStack(spacing: 8) {
            Toggle("Iso", isOn: $isometricMode).fixedSize()
            Spacer()
            Stepper(
                value: Binding(
                    get: { Int(skill.sliceCount) },
                    set: { skill.sliceCount = Int16($0); services.coreData.save() }
                ),
                in: 0...30
            ) {
                Text(skill.sliceCount > 0
                     ? "\(skill.sliceCount) slice\(skill.sliceCount == 1 ? "" : "s")"
                     : "No slices")
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            .fixedSize()
        }

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Instructions")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                if !skill.instructions.isEmpty {
                    Button {
                        if services.audio.isSpeaking { services.audio.stopSpeaking() }
                        else { services.audio.speak(skill.instructions) }
                    } label: {
                        Image(systemName: services.audio.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                }
                Button { editingInstructions = true } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
            }
            if skill.instructions.isEmpty {
                Text("Tap pencil to add instructions.")
                    .font(.callout).foregroundStyle(.tertiary)
            } else {
                Text(skill.instructions)
                    .font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var runningView: some View {
        VStack(spacing: 16) {
            if vm.activeSliceCount > 0 {
                Text("Slice \(vm.currentSliceNumber) of \(vm.activeSliceCount)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
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

    @ViewBuilder
    private var idleBottomBar: some View {
        if vm.phase == .idle {
            HStack(spacing: 0) {
                bottomButton(
                    vm.familyIdx == 0 && vm.roundIdx == 0 ? "Start" : "Start Set",
                    "play.fill",
                    prominent: true
                ) { vm.startSet() }
                bottomButton("Log", "square.and.pencil") { vm.skipToLog() }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(.bar)
        }
    }

    private func bottomButton(
        _ label: String,
        _ symbol: String,
        enabled: Bool = true,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(prominent ? .title2 : .title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(prominent ? Color.accentColor : .primary)
        }
        .disabled(!enabled)
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
            HStack(spacing: 5) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .imageScale(.small)
                    .foregroundStyle(heartRate.bpm != nil ? .green : .secondary)
                Image(systemName: "heart.fill")
                    .imageScale(.small)
                    .foregroundStyle(.red)
                if let bpm = heartRate.bpm {
                    Text("\(bpm)")
                        .monospacedDigit()
                        .font(.callout.bold())
                }
            }
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
