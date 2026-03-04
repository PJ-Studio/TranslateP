//
//  TranslateContentView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/17.
//

import SwiftUI
import AppKit

struct TranslateContentView: View {
    @ObservedObject var viewModel: TranslateViewModel
    @StateObject private var speechManager = SpeechManager()
    @State private var isCopied = false
    @State private var wordPhonetics: String? = nil
    @State private var isTranslationCompleted = false
    
    // 拖拽相关状态
    @State private var isDragging = false

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
                .frame(width: viewModel.translateWindowWidth)
                .frame(height: min(viewModel.estimatedTextHeight, viewModel.maxTranslateWindowHeight))
                .scrollIndicators(.never)

                if let wordPhonetics = wordPhonetics, isTranslationCompleted, viewModel.isSourceLanguageEnglish {
                    HStack {
                        Text(wordPhonetics)
                            .font(.callout)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                }
                
                HStack {
                    // 只有翻译完成时才显示朗读和复制按钮
                    if isTranslationCompleted {
                        Button(action: {
                            let language = viewModel.isSourceLanguageEnglish ? "en-US" : "zh-CN"
                            speechManager.speakText(viewModel.sourceString, language: language)
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
                    }
                    
                    Button(action: {
                        viewModel.togglePin()
                    }) {
                        Image(systemName: viewModel.isPinned ? "pin.fill" : "pin")
                            .foregroundColor(viewModel.isPinned ? .blue : .gray)
                            .fixedSize()
                            .rotationEffect(.degrees(45))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
            }
        }
        .fixedSize()
        .onAppear {
            // 在 pin 状态下启用窗口拖拽
            if viewModel.isPinned {
                enableWindowDragging()
            }
        }
        .onDisappear(perform: {
            speechManager.stopSpeaking()
        })
        .onChange(of: viewModel.isPinned) {
             if viewModel.isPinned {
                 enableWindowDragging()
             } else {
                 disableWindowDragging()
             }
         }
        .onChange(of: viewModel.fontSize) {
            viewModel.adjustWindowPosition()
        }
        .translationTask(viewModel.configuration) { session in
            // 检查 configuration 是否有效
            guard viewModel.configuration != nil else { 
                print("配置无效")
                return 
            }
            
            print("开始翻译: \(viewModel.sourceString), 反转状态: \(viewModel.isLanguageReversed)")
            
            // 翻译开始时重置状态
            DispatchQueue.main.async {
                isTranslationCompleted = false
                wordPhonetics = nil
            }
            
            do {
                let resp = try await session.translate(viewModel.sourceString)
                print("翻译成功: \(resp.targetText)")
                DispatchQueue.main.async {
                    viewModel.targetString = resp.targetText
                    // 只有源语言是英文时才获取音标
                    wordPhonetics = viewModel.isSourceLanguageEnglish ? WordService.getWordPhonetics(for: viewModel.sourceString) : nil
                    isTranslationCompleted = true
                    viewModel.adjustWindowPosition()
                }
            } catch is CancellationError {
                // 忽略取消错误
            } catch {
                print("翻译错误: \(error)")
                DispatchQueue.main.async {
                    isTranslationCompleted = false
                }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCopied = false
        }
    }
    
    // 启用窗口拖拽
    private func enableWindowDragging() {
        if let window = Translate.findWindow(Translate.translateWindow) {
            window.isMovableByWindowBackground = true
        }
    }
    
    // 禁用窗口拖拽
    private func disableWindowDragging() {
        if let window = Translate.findWindow(Translate.translateWindow) {
            window.isMovableByWindowBackground = false
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
        viewModel.targetString = "阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿阿水大师的阿斯顿阿"
    }
}
