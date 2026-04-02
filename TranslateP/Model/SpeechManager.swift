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
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speakText(_ text: String, language: String = "en-US") {
        guard !text.isEmpty else { return }
        
        // 已在播放则停止（切换状态）
        if synthesizer.isSpeaking {
            stopSpeaking()
            return
        }
        
        // AVSpeechSynthesizer 必须在主线程操作
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
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
