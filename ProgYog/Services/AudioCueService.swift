//
//  AudioCueService.swift
//  ProgYog
//
//  Uses system sounds as placeholders. Swap with bundled .caf files later.
//

import Foundation
import AVFoundation
import AudioToolbox

enum AudioCue {
    case countdownBeep      // 3-2-1 ticks
    case terminal           // end of set
    case halfwayBell        // 30s mark for symmetrical moves
    case roundStart
    case roundEnd

    var systemSoundID: SystemSoundID {
        switch self {
        case .countdownBeep: return 1057   // Tink
        case .terminal:      return 1005   // NewMail
        case .halfwayBell:   return 1013   // SMSReceived
        case .roundStart:    return 1117   // BeginRecording
        case .roundEnd:      return 1118   // EndRecording
        }
    }

    var isAlert: Bool {
        switch self {
        case .terminal, .roundEnd: return true
        default: return false
        }
    }
}

@MainActor
final class AudioCueService: NSObject, ObservableObject {
    @Published private(set) var isSpeaking: Bool = false

    private let synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.mixWithOthers, .duckOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.delegate = self
    }

    func play(_ cue: AudioCue) {
        if cue.isAlert {
            AudioServicesPlayAlertSound(cue.systemSoundID)
        } else {
            AudioServicesPlaySystemSound(cue.systemSoundID)
        }
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
        isSpeaking = true
    }

    func stopSpeaking() {
        synth.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension AudioCueService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
