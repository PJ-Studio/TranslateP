//
//  TranslateContentView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/17.
//

import SwiftUI
import AVFoundation
import AppKit

struct TranslateContentView: View {
    @ObservedObject var viewModel: TranslateViewModel
    @StateObject private var speechManager = SpeechManager()
    @State private var isCopied = false

    var body: some View {
        ZStack {
            TranslateContentBGView()
            
            VStack {
                ScrollView {
                    HStack {
                        Text(viewModel.targetString)
                            .padding(EdgeInsets(top: 15, leading: 10, bottom: 5, trailing: 0))
                            .font(.system(size: viewModel.fontSize))
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .frame(minWidth: 70, maxWidth: 300, minHeight: 45, maxHeight: 500)
                .scrollIndicators(.never)

                Spacer()
                
                HStack {
                    Button(action: {
                        speechManager.speakText(viewModel.sourceString)
                    }) {
                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .foregroundColor(.gray)
                            .fixedSize()
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        copyTranslatedText()
                    }) {
                        Image(systemName: isCopied ? "checkmark" : "document.on.document")
                            .foregroundColor(.gray)
                            .fixedSize()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
            }
        }
        .fixedSize()
        .translationTask(viewModel.configuration) { session in
            do {
                let resp = try await session.translate(viewModel.sourceString)
                DispatchQueue.main.async {
                    viewModel.targetString = resp.targetText
                }
            } catch {
                print("翻译错误: \(error)")
            }
        }
    }
    
    private func copyTranslatedText() {
        guard !viewModel.targetString.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(viewModel.targetString, forType: .string)
        
        // 显示复制成功反馈（无动画，避免布局抖动）
        isCopied = true
        
        // 2秒后恢复原始图标
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCopied = false
        }
    }
}

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

struct TranslateContentBGView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .foregroundStyle(Color.black.opacity(0.7))
            .shadow(radius: 4)
    }
}

#Preview {
    var viewModel = TranslateViewModel()
    
    TranslateContentView(viewModel: viewModel)
    .onAppear {
        viewModel.targetString = "阿水大师的阿斯顿阿斯顿爱上爱上"
    }
}
