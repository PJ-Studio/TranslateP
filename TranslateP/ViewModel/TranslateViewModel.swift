//
//  TranslateViewModel.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/3.
//

import SwiftUI
import Translation

class TranslateViewModel: ObservableObject {
    private var commandCCount = 0
    private var lastCommandCTime = Date()
    private let commandCInterval: TimeInterval = 0.5
    
    var sourceString = "双击 Command + C 分析剪贴板内容"
    @Published var targetString: String = ""
    // 每次 configuration 发生变化，都会触发一次完整翻译
    @Published var configuration: TranslationSession.Configuration?
    @Published var fontSize: Double = 14

    
    func commandCKeyEvent() {
        let now = Date()
        
        if now.timeIntervalSince(lastCommandCTime) <= commandCInterval {
            commandCCount += 1
            
            // 只在第二次按下时触发翻译
            if commandCCount == 2 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let clipboardString = NSPasteboard.general.string(forType: .string) {
                        self.sourceString = clipboardString
                        triggerTranslation()
                    }
                }
                commandCCount = 0 // 重置计数
            }
        } else {
            commandCCount = 1 // 重新开始计数
        }
        
        lastCommandCTime = now
    }
    
    func triggerTranslation() {
        if configuration == nil {
            configuration = .init(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "zh"))
        } else {
            configuration?.invalidate()
        }
    }
}
