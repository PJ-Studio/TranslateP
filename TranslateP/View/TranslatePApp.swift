//
//  TranslatePApp.swift
//  TranslateP
//
//  Created by ByteDance on 2024/11/2.
//

import SwiftUI
import Carbon.HIToolbox
import Translation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 dock 图标
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct TranslatePApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var commandCCount = 0
    @State private var lastCommandCTime = Date()
    private let commandCInterval: TimeInterval = 0.5
    
    @State private var configuration: TranslationSession.Configuration?
    @State private var windowPosition: CGPoint = .zero
    @State private var mouseEventMonitor: Any?
    
    @State var sourceText = "双击 Command + C 分析剪贴板内容"
    
    // 添加键盘监听器的状态变量
    @State private var keyboardMonitor: Any?
    
    var body: some Scene {
        WindowGroup {
            HStack {
                Text(sourceText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 150)
            }
            .onAppear {
                setupKeyboardMonitoring()
                setupWindow()
                setupMouseMonitoring()
                hideWindow()
                
                // 关闭其他窗口
                if NSApplication.shared.windows.count > 1 {
                    NSApplication.shared.windows.dropFirst().forEach { window in
                        window.close()
                    }
                }
            }
            .onDisappear {
                removeKeyboardMonitoring()
                removeMouseMonitoring()
            }
            .translationTask(configuration) { session in
                if let resp = try? await session.translate(sourceText) {
                    sourceText = resp.targetText
                    showWindowAtMouse()
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 150, height: 0)
    }
    
    private func hideWindow() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.orderOut(nil)
            }
        }
    }
    
    private func showWindowAtMouse() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                let mouseLocation = NSEvent.mouseLocation
                let screenFrame = NSScreen.main?.frame ?? .zero
                
                let contentHeight = window.contentView?.fittingSize.height ?? 100
                
                var x = mouseLocation.x - (150 / 2)
                var y = mouseLocation.y
                
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
                window.level = .floating
                window.styleMask.remove(.resizable)
                window.isOpaque = false
                window.hasShadow = true
                
                window.orderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
    
    private func setupKeyboardMonitoring() {
        // 设置新的监听器
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            if event.type == .keyDown {
                if event.modifierFlags.contains(.command) && event.keyCode == 8 { // Command + C
                    let now = Date()
                    
                    if now.timeIntervalSince(lastCommandCTime) <= commandCInterval {
                        commandCCount += 1
                        
                        // 只在第二次按下时触发翻译
                        if commandCCount == 2 {
                            DispatchQueue.main.async {
                                if let clipboardString = NSPasteboard.general.string(forType: .string) {
                                    sourceText = clipboardString
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
            }
        }
    }
    
    private func triggerTranslation() {
        if configuration == nil {
            configuration = .init(source: Locale.Language(identifier: "en"), target: Locale.Language(identifier: "zh"))
        } else {
            configuration?.invalidate()
        }
    }
    
    private func setupWindow() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.level = .floating
                window.styleMask = [.borderless]
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.backgroundColor = .windowBackgroundColor
                window.collectionBehavior.remove(.fullScreenPrimary)
                
                window.minSize = NSSize(width: 150, height: 0)
                window.maxSize = NSSize(width: 150, height: CGFloat.infinity)
            }
        }
    }
    
    private func setupMouseMonitoring() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            if let window = NSApplication.shared.windows.first {
                let clickLocation = NSEvent.mouseLocation
                let frame = NSRect(
                    x: window.frame.minX - 5,
                    y: window.frame.minY - 5,
                    width: window.frame.width + 10,
                    height: window.frame.height + 10
                )
                
                if !frame.contains(clickLocation) {
                    hideWindow()
                }
            }
        }
    }
    
    private func removeMouseMonitoring() {
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
    }
    
    private func removeKeyboardMonitoring() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }
}
