//
//  TranslateContentView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/17.
//

import SwiftUI
import AVFoundation

struct TranslateContentView: View {
    @ObservedObject var viewModel: TranslateViewModel
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var speechManager = SpeechManager()

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
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                        Spacer()
                    }
                }
                .frame(minWidth: 70, maxWidth: 300, minHeight: 45, maxHeight: 500)
                .scrollIndicators(.never)
                
                Rectangle()
                    .frame(height: 0.5)
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                    .foregroundStyle((colorScheme == .dark ? Color.black : Color.white).opacity(0.4))

                Spacer()
                
                HStack {
                    Button(action: {
                        speechManager.speakText(viewModel.sourceString)
                    }) {
                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .foregroundColor(colorScheme == .dark ? .black.opacity(0.4) : .gray)
                            .fixedSize()
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .foregroundStyle(colorScheme == .dark ? Color.gray : Color.black.opacity(0.7))
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
