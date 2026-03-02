//
//  MenuView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/16.
//

import SwiftUI
import Translation

struct MenuView: View {
    @State private var hasInit = false
    @State private var targetLang: Int = 0 // 翻译前
    @State private var sourceLang: Int = 0 // 翻译后
    
    @ObservedObject var viewModel: TranslateViewModel
    @StateObject private var speechManager = SpeechManager()
    @State private var isCopied = false
    
    @State private var keyboardCount = 0
    @State private var isArrowFlipped = false // 箭头翻转动画状态
    
    /// 从 Bundle 获取应用版本号
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }

    private func copyToPasteboard(_ text: String) {
        guard !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }

    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Form {
                    Section("功能设置") {
                        Toggle("两次 ⌘ + C 翻译", isOn: $viewModel.keyboardEventOn)
                        Toggle("剪贴板截图翻译", isOn: $viewModel.clipboardSnapshotOn)
                        
                        HStack {
                            Text("英文")
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.toggleLanguageDirection()
                                }
                            }) {
                                Image(systemName: "arrowshape.right")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                    .scaleEffect(x: viewModel.isLanguageReversed ? -1 : 1, y: 1)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Text("中文")
                        }
                        .padding(.vertical, 5)
                    }
                    
                    Section("UI 设置") {
                        HStack {
                            Text("文字大小  \(Int(viewModel.fontSize))pt")
                            Spacer()
                            Slider(value: $viewModel.fontSize, in: 10...30, step: 1)
                                .frame(width: 150)
                                .controlSize(.small)
                        }
                    }
                    
                    Section("查词") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Button(action: {
                                    viewModel.searchWord()
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)
                                
                                TextField("", text: $viewModel.searchText)
                                    .textFieldStyle(.plain)
                                    .labelsHidden() // 隐藏 Form 默认生成的标签占位
                                    .onSubmit {
                                        viewModel.searchWord()
                                    }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            
                            if !viewModel.searchResult.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.searchResult)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    if let phonetics = viewModel.searchPhonetics {
                                        Text(phonetics)
                                            .font(.callout)
                                            .foregroundColor(.secondary.opacity(0.8))
                                    }
                                }
                                .padding(.top, 4)
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        // 朗读查询的源文本 (searchText)
                                        let language = viewModel.isLanguageReversed ? "zh-CN" : "en-US"
                                        speechManager.speakText(viewModel.searchText, language: language)
                                    }) {
                                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        copyToPasteboard(viewModel.searchResult)
                                    }) {
                                        Image(systemName: isCopied ? "checkmark" : "document.on.document")
                                            .foregroundColor(.gray)
                                            .frame(width: 16, height: 16)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .frame(minHeight: 350)
                
                VStack(spacing: 12) {
                    HStack {
                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            HStack {
                                Image(systemName: "power")
                                Text("退出")
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.footnote)
                        
                        Spacer()
                        
                        Text("软件版本：1.0.4")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 320)
        .frame(maxHeight: 500)
        .translationTask(viewModel.configuration) { session in
            guard !viewModel.searchText.isEmpty else { return }
            do {
                let response = try await session.translate(viewModel.searchText)
                viewModel.searchResult = response.targetText
            } catch {
                viewModel.searchResult = "查询失败: \(error.localizedDescription)"
            }
        }
        .onAppear {
            viewModel.setupKeyboardMonitoring()
            viewModel.setupMouseMonitoring()
        }
        .onDisappear {
            speechManager.stopSpeaking()
            // 每次关闭菜单时清理查词状态，保证下次打开是干净的
            viewModel.searchText = ""
            viewModel.searchResult = ""
            viewModel.searchPhonetics = nil
        }
    }
}

#Preview {
    MenuView(viewModel: TranslateViewModel())
        .frame(width: 300)
}
