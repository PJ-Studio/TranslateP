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
    
    var sourceString = ""
    let successDownloadString: String = "词典已下载"
    
    private var keyboardMonitor: Any?
    private var mouseEventMonitor: Any?
    private var clipboardMonitor = ClipboardMonitor()
    
    /// 是否开启双击剪贴板识别截图翻译
    @Published var clipboardSnapshotOn: Bool = false {
        didSet {
            if clipboardSnapshotOn {
                setupClipboardMonitoring()
            } else {
                clipboardMonitor.stopMonitoring()
            }
        }
    }
    /// 是否开启双击 command + c 快捷键监听功能
    @Published var keyboardEventOn: Bool = false
    ///是否开启截图翻译功能
    @Published var screenshotEventOn: Bool = false
    @Published var targetString: String = DefualtTextString
    /// 每次 configuration 发生变化，都会触发一次完整翻译
    @Published var configuration: TranslationSession.Configuration?
    /// 翻译后文案字体大小
    @Published var fontSize: CGFloat = 14
    @Published var hasPermission: Bool = Translate.hasShortcutPermission()
    /// 翻译窗口是否被 pin 固定
    @Published var isPinned: Bool = false
    /// 记住被 pin 时的窗口位置
    private var pinnedWindowPosition: NSPoint?
    /// 是否反转语言（true: 中文->英文，false: 英文->中文）
    @Published var isLanguageReversed: Bool = false
    /// 查词输入框内容
    @Published var searchText: String = "" {
        didSet {
            if searchText.isEmpty {
                searchResult = ""
                searchPhonetics = nil
            }
        }
    }
    /// 查词结果
    @Published var searchResult: String = ""
    /// 查词音标
    @Published var searchPhonetics: String? = nil
    
    /// 翻译窗口固定宽度
    let translateWindowWidth: CGFloat = 300
    /// 翻译结果窗口最大高度（默认 1000，且受屏幕高度限制）
    var maxTranslateWindowHeight: CGFloat {
        let screenHeight = (Translate.findWindow(Translate.translateWindow)?.screen ?? NSScreen.main)?.visibleFrame.height ?? 800
        // 最大不超过 1000，且保留 60pt 的边距
        return min(500, screenHeight - 60)
    }
    
    /// 根据当前内容和字体大小估算出的高度（仅文本部分）
    var estimatedTextHeight: CGFloat {
        if targetString == TranslateViewModel.DefualtTextString || targetString.isEmpty {
            return 40 // 默认初始高度
        }
        
        let text = targetString
        let font = NSFont.systemFont(ofSize: fontSize)
        // 减去 Text 组件的内边距 (leading: 10)
        let contentWidth = translateWindowWidth - 10
        
        let constraintRect = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, 
                                          options: [.usesLineFragmentOrigin, .usesFontLeading], 
                                          attributes: [.font: font], 
                                          context: nil)
        
        // 文本内边距：top 15 + bottom 5 = 20
        let textPadding: CGFloat = 20
        
        return ceil(boundingBox.height) + textPadding
    }

    /// 自动调整窗口位置，确保不超出屏幕边缘
    func adjustWindowPosition() {
        // 稍作延迟，等待 SwiftUI 渲染完成并更新 window frame
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // 稍微增加一点延迟，确保渲染完成
            guard let window = Translate.findWindow(Translate.translateWindow) else { return }
            // 使用窗口所在的屏幕，如果找不到则使用主屏幕
            let screen = window.screen ?? NSScreen.main
            let screenFrame = screen?.visibleFrame ?? .zero
            let windowFrame = window.frame
            
            var newOrigin = windowFrame.origin
            
            // 1. 检查高度是否超出当前屏幕可见高度
            if windowFrame.height > screenFrame.height {
                // 如果窗口本身比屏幕还高（虽然我们已经限制了，但作为兜底），设置起始位置为屏幕顶部
                newOrigin.y = screenFrame.maxY - windowFrame.height
            } else {
                // 2. 检查顶部是否超出
                if windowFrame.maxY > screenFrame.maxY {
                    newOrigin.y = screenFrame.maxY - windowFrame.height
                }
                
                // 3. 检查底部是否超出
                if newOrigin.y < screenFrame.minY {
                    newOrigin.y = screenFrame.minY
                }
            }
            
            // 4. 检查右侧是否超出
            if windowFrame.maxX > screenFrame.maxX {
                newOrigin.x = screenFrame.maxX - windowFrame.width
            }
            
            // 5. 检查左侧是否超出
            if newOrigin.x < screenFrame.minX {
                newOrigin.x = screenFrame.minX
            }
            
            if newOrigin != windowFrame.origin {
                window.setFrameOrigin(newOrigin)
                
                // 如果是 Pin 模式，同步更新记录的位置
                if self.isPinned {
                    self.pinnedWindowPosition = newOrigin
                }
            }
        }
    }

    
    @Published var dictDisplayString: String = "词典安装完毕后，即可使用"
    @Published var dictDownloaded: Bool = UserDefaults.standard.bool(forKey: Translate.hasDownloadedDict)
    
    @Published var permissionDisplayString: String = "给 TranslateP 添加访问“辅助功能”权限"
    
    private var commandCCount = 0
    private var lastCommandCTime = Date()
    private let commandCInterval: TimeInterval = 0.3
    private static let DefualtTextString = "..."
    
    func commandCKeyEvent() {
        if !keyboardEventOn {
            return
        }
        
        let now = Date()
        
        if now.timeIntervalSince(lastCommandCTime) <= commandCInterval {
            commandCCount += 1
            
            // 只在第二次按下时触发翻译
            if commandCCount == 2 {
                if let clipboardString = NSPasteboard.general.string(forType: .string) {
                    self.sourceString = clipboardString
                    self.targetString = TranslateViewModel.DefualtTextString
                    self.showWindowAtMouse()
                    triggerTranslation()
                    commandCCount = 0
                }
            }
        } else {
            commandCCount = 1
        }
        
        lastCommandCTime = now
    }
    
    /// 查词
    func searchWord() {
        guard !searchText.isEmpty else { return }
        
        // 触发翻译
        let (sourceLanguage, targetLanguage) = isLanguageReversed
            ? (Locale.Language(identifier: "zh"), Locale.Language(identifier: "en"))
            : (Locale.Language(identifier: "en"), Locale.Language(identifier: "zh"))
        
        if #available(macOS 15.0, *) {
            // 确保在主线程触发配置更新，避免多线程导致的 UI 崩溃
            DispatchQueue.main.async {
                // 重新使用 Configuration 触发机制，但确保每次都强制更新
                self.configuration?.invalidate()
                // 故意延迟一小会儿，确保 UI 线程能够感知到 configuration 的变化
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.configuration = .init(source: sourceLanguage, target: targetLanguage)
                    
                    // 如果源语言是英文，则获取音标
                    if !self.isLanguageReversed {
                        self.searchPhonetics = WordService.getWordPhonetics(for: self.searchText)
                    } else {
                        self.searchPhonetics = nil
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.searchResult = "当前系统版本不支持翻译功能"
            }
        }
    }
    
    func triggerTranslation() {
        let (sourceLanguage, targetLanguage) = isLanguageReversed 
            ? (Locale.Language(identifier: "zh"), Locale.Language(identifier: "en"))  // 中文->英文
            : (Locale.Language(identifier: "en"), Locale.Language(identifier: "zh"))  // 英文->中文
        if configuration == nil {
            configuration = .init(source: sourceLanguage, target: targetLanguage)
        } else {
            configuration?.invalidate()
        }
    }
    
    /// 切换 pin 状态
    func togglePin() {
        if !isPinned {
            // 准备 pin 时，记录当前窗口位置并设置窗口行为
            if let window = Translate.findWindow(Translate.translateWindow) {
                pinnedWindowPosition = window.frame.origin
                // 设置窗口在所有桌面显示
                window.collectionBehavior = [.canJoinAllSpaces]
                // 启用原生窗口拖拽
                window.isMovable = true
                window.isMovableByWindowBackground = true
            }
        } else {
            // 取消 pin 时，清除记录的位置并恢复正常窗口行为
            pinnedWindowPosition = nil
            if let window = Translate.findWindow(Translate.translateWindow) {
                // 恢复正常的桌面行为
                window.collectionBehavior = []
                window.isMovable = false
                window.isMovableByWindowBackground = false
            }
        }
        isPinned.toggle()
    }
    
    /// 反转翻译语言
    func toggleLanguageDirection() {
        isLanguageReversed.toggle()
        
        let (sourceLanguage, targetLanguage) = isLanguageReversed
            ? (Locale.Language(identifier: "zh"), Locale.Language(identifier: "en"))  // 中文->英文
            : (Locale.Language(identifier: "en"), Locale.Language(identifier: "zh"))  // 英文->中文
        
        // 确保在主线程更新 UI 相关的 configuration，防止 NSStatusItem 等系统 UI 控件发生多线程崩溃
        DispatchQueue.main.async {
            if self.configuration == nil {
                self.configuration = .init(source: sourceLanguage, target: targetLanguage)
            } else {
                self.configuration?.invalidate()
            }
        }
        
        // 如果查词框有内容，切换语言时自动触发一次重新查询
        if !searchText.isEmpty {
            searchWord()
        }
    }
    
    /// 当前源语言是否为英文
    var isSourceLanguageEnglish: Bool {
        return !isLanguageReversed
    }
    
    func setupKeyboardMonitoring() {
        if keyboardMonitor != nil {
            return
        }
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
        if mouseEventMonitor != nil {
            return
        }
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            // 如果窗口被 pin 了，则不自动关闭
            if self.isPinned {
                return
            }
            
            if let window = Translate.findWindow(Translate.translateWindow) {
                let clickLocation = NSEvent.mouseLocation
                let frame = NSRect(
                    x: window.frame.minX - 5,
                    y: window.frame.minY - 5,
                    width: window.frame.width + 10,
                    height: window.frame.height + 10
                )
                
                if !frame.contains(clickLocation) {
                    self.dismissTranslateWindow()
                }
            }
        }
    }
    
    func showWindowAtMouse() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 如果窗口已存在
            if Translate.findWindow(Translate.translateWindow) != nil {
                if self.isPinned {
                    // 如果窗口被 pin，直接在原地更新内容，不关闭窗口
                    // 窗口已经存在且被 pin，直接触发翻译即可
                    return
                } else {
                    // 如果窗口未被 pin，关闭后重新创建
                    self.dismissTranslateWindow()
                    // 等待窗口关闭
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.createNewTranslateWindow(usePinnedPosition: false)
                    }
                }
            } else {
                // 窗口不存在，创建新窗口
                let shouldUsePinnedPosition = self.isPinned && self.pinnedWindowPosition != nil
                if !shouldUsePinnedPosition {
                    // 当显示新窗口时，如果不是使用 pin 位置，则重置 pin 状态
                    self.isPinned = false
                }
                self.createNewTranslateWindow(usePinnedPosition: shouldUsePinnedPosition)
            }
        }
    }
    
    private func createNewTranslateWindow(usePinnedPosition: Bool = false) {
        openWindow(id: Translate.translateWindow)
        
        if let window = Translate.findWindow(Translate.translateWindow) {
            let screenFrame = NSScreen.main?.visibleFrame ?? .zero
            
            if usePinnedPosition, let pinnedPosition = pinnedWindowPosition {
                // 使用之前 pin 的位置
                var x = pinnedPosition.x
                var y = pinnedPosition.y
                
                // 确保窗口不会超出屏幕边界
                if x + 150 > screenFrame.maxX {
                    x = screenFrame.maxX - 150
                }
                if x < screenFrame.minX {
                    x = screenFrame.minX
                }
                if y + 100 > screenFrame.maxY {
                    y = screenFrame.maxY - 100
                }
                if y < screenFrame.minY {
                    y = screenFrame.minY
                }
                
                window.setFrameOrigin(NSPoint(x: x, y: y))
            } else {
                // 使用鼠标位置
                let mouseLocation = NSEvent.mouseLocation
                let contentHeight = window.contentView?.fittingSize.height ?? 100
                
                var x = mouseLocation.x - (150 / 2)
                var y = mouseLocation.y + 10
                
                if x + 150 > screenFrame.maxX {
                    x = screenFrame.maxX - 150
                }
                if x < screenFrame.minX {
                    x = screenFrame.minX
                }
                
                // 确保 y 轴位置合理，且窗口底部不超出屏幕
                if y + contentHeight > screenFrame.maxY {
                    y = screenFrame.maxY - contentHeight
                }
                if y - contentHeight < screenFrame.minY {
                    y = screenFrame.minY + contentHeight
                }
                
                window.setFrameOrigin(NSPoint(x: x, y: y - contentHeight))
            }
            
            // 如果是 pin 模式，设置窗口在所有桌面显示并启用拖拽
            if usePinnedPosition && isPinned {
                window.collectionBehavior = [.canJoinAllSpaces]
                window.isMovable = true
                window.isMovableByWindowBackground = true
            } else {
                window.isMovable = false
                window.isMovableByWindowBackground = false
            }
        }
    }
    
    func openDownloadDictWindow() {
        openWindow(id: Translate.downloadDictWindow)
    }
    
    func dismissDownloadDictWindow() {
        dismissWindow(id: Translate.downloadDictWindow)
    }
    
    /// 关闭翻译窗口并重置 pin 状态
    func dismissTranslateWindow() {
        // 在关闭前恢复窗口的正常行为
        if let window = Translate.findWindow(Translate.translateWindow) {
            window.collectionBehavior = []
            window.isMovable = false
            window.isMovableByWindowBackground = false
            // 移除窗口位置监听
            NotificationCenter.default.removeObserver(self, name: NSWindow.didMoveNotification, object: window)
        }
        isPinned = false
        pinnedWindowPosition = nil
        dismissWindow(id: Translate.translateWindow)
    }
    
    /// 更新被 pin 窗口的位置（用于拖拽后保存新位置）
    func updatePinnedWindowPosition() {
        if isPinned, let window = Translate.findWindow(Translate.translateWindow) {
            pinnedWindowPosition = window.frame.origin
        }
    }
    
    /// 设置剪贴板监听
    private func setupClipboardMonitoring() {
        clipboardMonitor.onImageDetected = { [weak self] image in
            self?.handleClipboardImage(image)
        }
        clipboardMonitor.startMonitoring()
    }
    
    /// 处理剪贴板中的图片
    private func handleClipboardImage(_ image: NSImage) {
        OCRService.recognizeText(from: image) { [weak self] recognizedText in
            guard let self = self,
                  let text = recognizedText,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            
            // 设置识别出的文字作为源文字
            self.sourceString = text
            self.targetString = TranslateViewModel.DefualtTextString
            
            // 显示翻译窗口
            self.showWindowAtMouse()
            
            // 触发翻译
            self.triggerTranslation()
        }
    }
}
