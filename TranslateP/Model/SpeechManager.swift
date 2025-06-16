//
//  SpeechManager.swift
//  TranslateP
//
//  Created by pjhubs on 2025/6/16.
//

import AVFoundation
import SwiftUI

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()
    private let speechQueue = DispatchQueue(label: "speech.queue", qos: .background)
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speakText(_ text: String) {
        guard !text.isEmpty else { return }
        
        if synthesizer.isSpeaking {
            stopSpeaking()
            return
        }
        
        speechQueue.async {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.5
            utterance.volume = 1.0
            
            DispatchQueue.main.async {
                self.isSpeaking = true
            }
            
            self.synthesizer.speak(utterance)
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
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
}
