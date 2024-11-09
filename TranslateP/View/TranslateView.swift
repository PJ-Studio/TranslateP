//
//  TranslateView.swift
//  TranslateP
//
//  Created by ByteDance on 2024/11/3.
//

import SwiftUI

struct TranslateView: View {
    @State private var windowPosition: CGPoint = .zero
    @State private var mouseEventMonitor: Any?
    @State private var keyboardMonitor: Any?
    @State private var isPasteDone: Bool = false

    @ObservedObject var viewModel: TranslateViewModel
    
    var body: some View {
        VStack {
            Text(viewModel.targetString)
                .fixedSize(horizontal: false, vertical: true)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            HStack {
                Spacer()
                
                if isPasteDone {
                    Text("✅")
                        .font(.system(size: 10))
                } else {
                    Image(systemName: "document.on.document")
                        .font(.system(size: 10))
                        .onTapGesture {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(viewModel.targetString, forType: .string)
                            isPasteDone = true
                        }
                }
                
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: "http://pjhubs.com")!)
                    }
            }
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
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
        .frame(width: 150)
        .translationTask(viewModel.configuration) { session in
            guard !Task.isCancelled else { return }
            do {
                let resp = try await session.translate(viewModel.sourceString)
                if !Task.isCancelled {
                    viewModel.targetString = resp.targetText
                    showWindowAtMouse()
                }
            } catch {
                print("翻译错误: \(error)")
            }
        }
    }
    
    private func setupWindow() {
        DispatchQueue.main.async {
            if let window = Translate.findWindow(Translate.translateWindow) {
                window.level = .floating
                window.styleMask = [.borderless, .fullSizeContentView]
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.backgroundColor = .clear
                window.collectionBehavior.remove(.fullScreenPrimary)
                
                // 设置窗口圆角
                window.isOpaque = false
                window.backgroundColor = .clear
                
                // 设置视图圆角
                if let contentView = window.contentView {
                    contentView.wantsLayer = true
                    contentView.layer?.cornerRadius = 8
                    contentView.layer?.masksToBounds = true
                    // 给contentView设置背景色
                    contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
                }
                
                window.minSize = NSSize(width: 150, height: 0)
                window.maxSize = NSSize(width: 150, height: CGFloat.infinity)
            }
        }
    }
    
    private func hideWindow() {
        isPasteDone = false
        DispatchQueue.main.async {
            if let window = Translate.findWindow(Translate.translateWindow) {
                window.orderOut(nil)
            }
        }
    }
    
    private func showWindowAtMouse() {
        DispatchQueue.main.async {()
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
                window.level = .floating
                window.styleMask.remove(.resizable)
                window.isOpaque = true
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
                    viewModel.commandCKeyEvent()
                }
            }
        }
    }
    
    private func setupMouseMonitoring() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            if let window = Translate.findWindow(Translate.translateWindow) {
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

