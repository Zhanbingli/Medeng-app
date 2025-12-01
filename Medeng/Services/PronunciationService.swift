//
//  PronunciationService.swift
//  Medeng
//
//  Text-to-speech service for medical term pronunciation
//

import Foundation
import AVFoundation

/// Service for pronouncing medical terms using text-to-speech
class PronunciationService: NSObject, ObservableObject {
    static let shared = PronunciationService()

    @Published var isSpeaking = false
    @Published var currentRate: Float = 0.4 // Slower for medical terms

    private let synthesizer = AVSpeechSynthesizer()
    private var lastUtterance: AVSpeechUtterance?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speak a medical term
    /// - Parameters:
    ///   - term: The medical term to pronounce
    ///   - language: Language code (default: en-US)
    ///   - rate: Speaking rate (0.0 - 1.0, default: 0.4 for slower medical pronunciation)
    func speak(_ term: String, language: String = "en-US", rate: Float? = nil) {
        // Stop any ongoing speech
        stop()

        configureAudioSessionIfNeeded()

        let utterance = AVSpeechUtterance(string: term)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate ?? currentRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        lastUtterance = utterance
        isSpeaking = true

        synthesizer.speak(utterance)
    }

    /// Speak a medical term with its definition
    /// - Parameter term: The medical term object
    func speakTerm(_ term: MedicalTerm) {
        speak(term.term)
    }

    /// Speak a medical term with its definition
    /// - Parameter term: The medical term object
    func speakTermWithDefinition(_ term: MedicalTerm) {
        stop()

        let text = "\(term.term). \(term.chineseTranslation). Definition: \(term.definition)"
        configureAudioSessionIfNeeded()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = currentRate
        utterance.volume = 1.0

        lastUtterance = utterance
        isSpeaking = true

        synthesizer.speak(utterance)
    }

    /// Stop current speech
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    /// Pause current speech
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    /// Resume paused speech
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }

    /// Prepare audio session for speech playback
    private func configureAudioSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Fallback silently if audio session cannot be configured
        }
    }

    /// Set speaking rate
    /// - Parameter rate: Speaking rate (0.0 - 1.0)
    func setRate(_ rate: Float) {
        currentRate = max(0.0, min(1.0, rate))
    }

    /// Get available voices for a language
    /// - Parameter language: Language code (e.g., "en-US")
    /// - Returns: Array of available voices
    func getVoices(for language: String) -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension PronunciationService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
}
