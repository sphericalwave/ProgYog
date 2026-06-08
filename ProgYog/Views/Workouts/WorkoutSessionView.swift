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
    @State private var sliceSheetPresented = false
    @State private var isometricMode: Bool = false

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
        ScrollView {
            sessionContent()
                .padding()
        }
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
        .sheet(isPresented: $sliceSheetPresented) {
            if let skill = vm.currentSkill {
                SliceConfigSheet(skill: skill) { count in
                    skill.sliceCount = Int16(count)
                    services.coreData.save()
                }
            }
        }
    }

    @ViewBuilder
    private func sessionContent() -> some View {
        VStack(spacing: 16) {
            if let skill = vm.currentSkill {
                instructionsCard(for: skill)
            }

            phaseContent
        }
    }

    private func instructionsCard(for skill: CDAbsSkill) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !skill.posterAssetNames.isEmpty {
                SkillPosterGallery(names: skill.posterAssetNames, contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
                    .clipped()
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
            } else if let data = skill.customPhotoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))
            }

            // Header: title + level stepper, then family + slices + iso
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(skill.name)
                        .font(.title2.bold())
                    Spacer()
                    Stepper(
                        onIncrement: vm.canProgressCurrentSkill ? { vm.progressCurrentSkill() } : nil,
                        onDecrement: vm.canRegressCurrentSkill ? { vm.regressCurrentSkill() } : nil
                    ) {
                        Text("Level \(skill.depth)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .fixedSize()
                }

                HStack(spacing: 8) {

                    Text(skill.family)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button { addVariantPresented = true } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.borderless)
                    .opacity(vm.currentFamily != nil ? 1 : 0)
                }

                HStack(spacing: 8) {
                    Toggle("Iso", isOn: $isometricMode)
                        .fixedSize()
                    
                    Spacer()

                    
                    Stepper(
                        value: Binding(
                            get: { Int(skill.sliceCount) },
                            set: { skill.sliceCount = Int16($0); services.coreData.save() }
                        ),
                        in: 0...30
                    ) {
                        Text(skill.sliceCount > 0 ? "\(skill.sliceCount) slice\(skill.sliceCount == 1 ? "" : "s")" : "No slices")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .fixedSize()
                }
            }
            .padding(12)

            // Body: instructions section
            if !skill.instructions.isEmpty {
                Divider()
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
                    Text(skill.instructions)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch vm.phase {
        case .idle:
            EmptyView()
        case .running:
            runningView
        case .logging, .finished:
            Color.clear.frame(height: 1)
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
                bottomButton("Slices", "pause.circle") { sliceSheetPresented = true }
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

private struct SliceConfigSheet: View {
    let skill: CDAbsSkill
    let onSave: (Int) -> Void

    @State private var count: Int
    @Environment(\.dismiss) private var dismiss

    init(skill: CDAbsSkill, onSave: @escaping (Int) -> Void) {
        self.skill = skill
        self.onSave = onSave
        _count = State(initialValue: Int(skill.sliceCount))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $count, in: 0...30) {
                        HStack {
                            Text("Slices")
                            Spacer()
                            Text(count > 0 ? "\(count) · \(count * 30)s" : "Off")
                                .monospacedDigit()
                                .bold()
                        }
                    }
                } footer: {
                    Text("Each slice is a 30-second isometric hold at a distinct position within the movement range — start, quarter, mid, three-quarter, end. \(count > 0 ? "\(count) × 30s = \(count * 30)s total." : "Set above 0 to activate.")")
                }
            }
            .navigationTitle("Isometric Slices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSave(count)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
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
