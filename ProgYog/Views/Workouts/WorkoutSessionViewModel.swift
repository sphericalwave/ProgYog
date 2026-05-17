//
//  WorkoutSessionViewModel.swift
//  ProgYog
//

import Foundation
import CoreData
import Combine

@MainActor
final class WorkoutSessionViewModel: ObservableObject {

    enum Phase: Equatable {
        case idle
        case running
        case logging
        case finished
    }

    @Published var phase: Phase = .idle
    @Published var roundIdx: Int = 0
    @Published var familyIdx: Int = 0
    @Published var secondsRemaining: Int = 60
    @Published var suggestion: ProgressionDecision = .`repeat`

    let totalRounds = 5
    let setDurationSec = 60
    let workoutCode: String
    let services: AppServices
    let moc: NSManagedObjectContext
    let session: Session
    private(set) var families: [CDSkillFamily] = []
    @Published private(set) var familyDepths: [NSManagedObjectID: Int16] = [:]

    private var timerTask: Task<Void, Never>?
    private var hrCancellable: AnyCancellable?
    private var sampleBuffer: [(t: TimeInterval, bpm: Int)] = []
    private var setStartedAt: Date = .distantPast
    private var lastBeepedSecond: Int = -1
    private var didPlayHalfwayBell: Bool = false

    init(workoutCode: String, services: AppServices, resuming existing: Session? = nil) {
        self.workoutCode = workoutCode
        self.services = services
        self.moc = services.coreData.moc

        if let existing {
            self.session = existing
        } else {
            self.session = Session(workoutCode: workoutCode, moc: moc)
            try? moc.save()
        }

        let fr: NSFetchRequest<CDSkillFamily> = CDSkillFamily.fetchRequest()
        fr.predicate = NSPredicate(format: "series == %@", workoutCode)
        fr.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        self.families = (try? moc.fetch(fr)) ?? []

        if existing != nil {
            restoreProgress()
        } else {
            for fam in families {
                familyDepths[fam.objectID] = computeStartingDepth(for: fam)
            }
        }
    }

    private func restoreProgress() {
        let logs = session.orderedSetLogs
        let famCount = max(families.count, 1)
        let totalSets = logs.count
        roundIdx = min(totalSets / famCount, totalRounds - 1)
        familyIdx = totalSets % famCount

        for fam in families {
            let lastInFam = logs
                .filter { $0.absSkill?.skillFamily == fam }
                .last
            if let last = lastInFam, let baseDepth = last.absSkill?.depth {
                switch last.decisionValue {
                case .progress: familyDepths[fam.objectID] = min(baseDepth + 1, 5)
                case .regress:  familyDepths[fam.objectID] = max(baseDepth - 1, 1)
                case .`repeat`:     familyDepths[fam.objectID] = baseDepth
                }
            } else {
                familyDepths[fam.objectID] = computeStartingDepth(for: fam)
            }
        }

        if totalSets >= totalRounds * famCount {
            session.endedAt = session.endedAt ?? Date()
            services.coreData.save()
            WorkoutCalendarBridge.syncCompleted(session)
            phase = .finished
        }
    }

    static func inProgressSession(for workoutCode: String, moc: NSManagedObjectContext) -> Session? {
        let fr: NSFetchRequest<Session> = Session.fetchRequest()
        fr.predicate = NSPredicate(format: "workoutCode == %@ AND endedAt == nil", workoutCode)
        fr.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        fr.fetchLimit = 1
        return (try? moc.fetch(fr))?.first
    }

    func discardSession() {
        moc.delete(session)
        services.coreData.save()
    }

    func setSessionNotes(_ text: String) {
        session.notes = text.isEmpty ? nil : text
        services.coreData.save()
        objectWillChange.send()
    }

    var currentFamily: CDSkillFamily? {
        guard familyIdx < families.count else { return nil }
        return families[familyIdx]
    }

    var currentDepth: Int16 {
        guard let fam = currentFamily else { return 1 }
        return familyDepths[fam.objectID] ?? 1
    }

    var currentSkill: CDAbsSkill? {
        guard let fam = currentFamily else { return nil }
        let depth = currentDepth
        let skills = (fam.absSkills as? Set<CDAbsSkill>) ?? []
        return skills.first { $0.depth == depth }
    }

    /// Depths that actually exist for the current family, sorted ascending.
    /// Bounds the manual level override to skills that really exist (a depth
    /// with no skill would make `currentSkill` nil and blank the view).
    private var currentFamilyDepths: [Int16] {
        guard let fam = currentFamily else { return [] }
        let skills = (fam.absSkills as? Set<CDAbsSkill>) ?? []
        return skills.map(\.depth).sorted()
    }

    var canRegressCurrentSkill: Bool {
        guard let min = currentFamilyDepths.first else { return false }
        return currentDepth > min
    }

    var canProgressCurrentSkill: Bool {
        guard let max = currentFamilyDepths.last else { return false }
        return currentDepth < max
    }

    func regressCurrentSkill() {
        guard let fam = currentFamily, let min = currentFamilyDepths.first else { return }
        familyDepths[fam.objectID] = Swift.max(currentDepth - 1, min)
    }

    func progressCurrentSkill() {
        guard let fam = currentFamily, let max = currentFamilyDepths.last else { return }
        familyDepths[fam.objectID] = Swift.min(currentDepth + 1, max)
    }

    var headerLine: String {
        "Round \(roundIdx + 1) of \(totalRounds) · Skill \(familyIdx + 1) of \(families.count)"
    }

    var isFirstSetOfRound: Bool { familyIdx == 0 }
    var isLastSetOfRound: Bool { familyIdx == families.count - 1 }

    func startSet() {
        guard let skill = currentSkill else { return }
        phase = .running
        secondsRemaining = setDurationSec
        sampleBuffer.removeAll()
        setStartedAt = Date()
        lastBeepedSecond = -1
        didPlayHalfwayBell = false
        suggestion = computeSuggestion(for: skill)

        if isFirstSetOfRound { services.audio.play(.roundStart) }
        services.audio.speak("\(skill.name), level \(skill.depth)")

        subscribeHR()
        startTimer()
    }

    func cancel() {
        timerTask?.cancel()
        timerTask = nil
        hrCancellable?.cancel()
        services.audio.stopSpeaking()
        phase = .finished
    }

    func skipToLog() {
        guard phase == .idle || phase == .running else { return }
        timerTask?.cancel()
        timerTask = nil
        hrCancellable?.cancel()
        services.audio.stopSpeaking()
        suggestion = currentSkill.map(computeSuggestion(for:)) ?? .`repeat`
        phase = .logging
    }

    /// Min/max/avg HR over the just-finished set, from the live sample buffer.
    /// Valid during `.logging` (the buffer is cleared only on the next
    /// `startSet`). Same math as `recordLog` persists onto the `SetLog`.
    var currentSetHRStats: (min: Int, max: Int, avg: Int)? {
        let bpms = sampleBuffer.map(\.bpm)
        guard let lo = bpms.min(), let hi = bpms.max() else { return nil }
        return (lo, hi, bpms.reduce(0, +) / max(bpms.count, 1))
    }

    func recordLog(_ entry: SetLogSheet.Entry) {
        guard let skill = currentSkill else { return }

        let log = SetLog(context: moc)
        log.id = UUID()
        log.session = session
        log.absSkill = skill
        log.roundIndex = Int16(roundIdx)
        log.orderInRound = Int16(familyIdx)
        log.reps = Int16(entry.reps)
        log.rom = Int16(entry.rom)
        log.rpt = Int16(entry.rpt)
        log.rpe = Int16(entry.rpe)
        log.rpd = Int16(entry.rpd)
        log.notes = entry.notes.isEmpty ? nil : entry.notes
        log.durationSec = Int16(setDurationSec)
        log.decision = entry.decision.rawValue
        log.loggedAt = Date()

        let bpms = sampleBuffer.map { $0.bpm }
        if let lo = bpms.min(), let hi = bpms.max() {
            log.hrMin = Int16(lo)
            log.hrMax = Int16(hi)
            log.hrAvg = Int16(bpms.reduce(0, +) / max(bpms.count, 1))
        }

        for s in sampleBuffer {
            let sample = HRSample(context: moc)
            sample.t = s.t
            sample.bpm = Int16(s.bpm)
            sample.setLog = log
        }

        if let fam = currentFamily {
            let current = familyDepths[fam.objectID] ?? 1
            let next: Int16
            switch entry.decision {
            case .progress: next = min(current + 1, 5)
            case .regress:  next = max(current - 1, 1)
            case .`repeat`:     next = current
            }
            familyDepths[fam.objectID] = next
        }

        services.coreData.save()
        advance()
    }

    private func advance() {
        if isLastSetOfRound { services.audio.play(.roundEnd) }
        familyIdx += 1
        if familyIdx >= families.count {
            familyIdx = 0
            roundIdx += 1
        }
        if roundIdx >= totalRounds {
            session.endedAt = Date()
            services.coreData.save()
            WorkoutCalendarBridge.syncCompleted(session)
            phase = .finished
        } else {
            phase = .idle
        }
    }

    private func subscribeHR() {
        hrCancellable = services.heartRate.$bpm
            .compactMap { $0 }
            .sink { [weak self] bpm in
                guard let self else { return }
                let t = Date().timeIntervalSince(self.setStartedAt)
                self.sampleBuffer.append((t: t, bpm: bpm))
            }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while let self, !Task.isCancelled, await self.secondsRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await self.tick()
            }
        }
    }

    private func tick() {
        secondsRemaining -= 1

        if secondsRemaining <= 3 && secondsRemaining > 0 && lastBeepedSecond != secondsRemaining {
            services.audio.play(.countdownBeep)
            lastBeepedSecond = secondsRemaining
        }

        let halfway = setDurationSec / 2
        if !didPlayHalfwayBell, secondsRemaining == halfway {
            services.audio.play(.halfwayBell)
            didPlayHalfwayBell = true
        }

        if secondsRemaining <= 0 {
            services.audio.play(.terminal)
            hrCancellable?.cancel()
            phase = .logging
        }
    }

    private func computeStartingDepth(for family: CDSkillFamily) -> Int16 {
        let fr: NSFetchRequest<SetLog> = SetLog.fetchRequest()
        fr.predicate = NSPredicate(format: "absSkill.skillFamily == %@", family)
        fr.sortDescriptors = [NSSortDescriptor(key: "loggedAt", ascending: false)]
        fr.fetchLimit = 1
        guard let last = (try? moc.fetch(fr))?.first,
              let lastDepth = last.absSkill?.depth else { return 1 }
        switch last.decisionValue {
        case .progress: return min(lastDepth + 1, 5)
        case .regress:  return max(lastDepth - 1, 1)
        case .`repeat`:     return lastDepth
        }
    }

    private func computeSuggestion(for skill: CDAbsSkill) -> ProgressionDecision {
        let fr: NSFetchRequest<SetLog> = SetLog.fetchRequest()
        fr.predicate = NSPredicate(format: "absSkill == %@", skill)
        fr.sortDescriptors = [NSSortDescriptor(key: "loggedAt", ascending: true)]
        let logs = (try? moc.fetch(fr)) ?? []
        let rated = logs.map { $0.ratedSet }
        return ProgressionEvaluator().suggest(from: rated)
    }
}
