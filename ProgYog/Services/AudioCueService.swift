//
//  AudioCueService.swift
//  ProgYog
//
//  Tones generated via AVAudioEngine so .playback session bypasses silent switch.
//

import Foundation
import AVFoundation

enum AudioCue {
    case countdownBeep      // 3-2-1 ticks
    case terminal           // end of set
    case halfwayBell        // 30s mark for symmetrical moves
    case roundStart
    case roundEnd

    // (frequency Hz, duration s, amplitude 0–1)
    var tone: (Float, Float, Float) {
        switch self {
        case .countdownBeep: return (880,  0.08, 0.4)
        case .terminal:      return (1047, 0.35, 0.5)
        case .halfwayBell:   return (659,  0.18, 0.4)
        case .roundStart:    return (880,  0.12, 0.5)
        case .roundEnd:      return (523,  0.40, 0.5)
        }
    }
}

@MainActor
final class AudioCueService: NSObject, ObservableObject {
    @Published private(set) var isSpeaking: Bool = false

    private let synth = AVSpeechSynthesizer()
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    private var engineReady = false

    override init() {
        super.init()
        synth.delegate = self
    }

    private func setupEngineIfNeeded() {
        guard !engineReady else { return }
        engineReady = true
#if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .default,
            options: [.mixWithOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
#endif
        engine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    func play(_ cue: AudioCue) {
        setupEngineIfNeeded()
        if !engine.isRunning { try? engine.start() }
        let (freq, duration, amplitude) = cue.tone
        let frameCount = AVAudioFrameCount(sampleRate * Double(duration))
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let samples = buffer.floatChannelData![0]
        let fadeFrames = min(Int(sampleRate * 0.005), Int(frameCount) / 4)
        for i in 0..<Int(frameCount) {
            var env: Float = 1.0
            if i < fadeFrames { env = Float(i) / Float(fadeFrames) }
            else if i > Int(frameCount) - fadeFrames { env = Float(Int(frameCount) - i) / Float(fadeFrames) }
            samples[i] = amplitude * env * sin(2 * Float.pi * freq * Float(i) / Float(sampleRate))
        }

        if !playerNode.isPlaying { playerNode.play() }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
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
