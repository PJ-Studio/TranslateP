//
//  TranslateViewModel.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/3.
//

import SwiftUI
import Translation

class TranslateViewModel: ObservableObject {
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    private var commandCCount = 0
    private var lastCommandCTime = Date()
    private let commandCInterval: TimeInterval = 0.5
    
    var sourceString = "双击 Command + C 分析剪贴板内容"
    
    @Published var keyboardEventOn: Bool = false
    @State private var keyboardMonitor: Any?
    
    @State private var mouseEventMonitor: Any?
    
    @Published var targetString: String = "..."
    /// 每次 configuration 发生变化，都会触发一次完整翻译
    @Published var configuration: TranslationSession.Configuration?
    /// 翻译后文案字体大小
    @Published var fontSize: CGFloat = 14

    func commandCKeyEvent() {
        if !keyboardEventOn {
            return
        }
        
        let now = Date()
        
        if now.timeIntervalSince(lastCommandCTime) <= commandCInterval {
            commandCCount += 1
            
            // 只在第二次按下时触发翻译
            if commandCCount == 2 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if let clipboardString = NSPasteboard.general.string(forType: .string) {
                        self.sourceString = clipboardString
                        self.targetString = "..."
                        self.showWindowAtMouse()
                        triggerTranslation()
                        commandCCount = 0 // 重置计数
                    }
                }
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
    
    func setupKeyboardMonitoring() {
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return }
            if event.type == .keyDown {
                if event.modifierFlags.contains(.command) && event.keyCode == 8 { // Command + C
                    self.commandCKeyEvent()
                }
            }
        }
    }
    
    func setupMouseMonitoring() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            if let window = Translate.findWindow(Translate.translateWindow) {
                let clickLocation = NSEvent.mouseLocation
                let frame = NSRect(
                    x: window.frame.minX - 5,
                    y: window.frame.minY - 5,
                    width: window.frame.width + 10,
                    height: window.frame.height + 10
                )
                
                if !frame.contains(clickLocation) {
                    self.dismissWindow(id: Translate.translateWindow)
                }
            }
        }
    }
    
    func showWindowAtMouse() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            openWindow(id: Translate.translateWindow)
            
            if let window = Translate.findWindow(Translate.translateWindow) {
                let mouseLocation = NSEvent.mouseLocation
                let screenFrame = NSScreen.main?.frame ?? .zero
                
                let contentHeight = window.contentView?.fittingSize.height ?? 100
                
                var x = mouseLocation.x - (150 / 2)
                var y = mouseLocation.y + 10
                
                if x + 150 > screenFrame.maxX {
                    x = screenFrame.maxX - 150
                }
                if x < screenFrame.minX {
                    x = screenFrame.minX
                }
                if y + contentHeight > screenFrame.maxY {
                    y = screenFrame.maxY - contentHeight
                }
                if y < screenFrame.minY {
                    y = screenFrame.minY
                }
                
                window.setFrameOrigin(NSPoint(x: x, y: y - contentHeight))
            }
        }
    }
}
