//
//  Translate.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/3.
//

import AppKit
import SwiftUI

struct Translate {
    static let translateWindow = "translate_window"
    static let settingsWindow = "settings_window"
    static let downloadDictWindow = "dict_window"
    
    /// 标记是否下载过词典
    static let hasDownloadedDict = "has_downloaded_dict"
    
    static func findWindow(_ identifier: String) -> NSWindow? {
        return NSApplication.shared.windows.filter({ ($0.identifier?.rawValue ?? "").contains(identifier)}).first
    }

    /// 检查是否有快捷键监听权限
    static func hasShortcutPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        return accessEnabled
    }
    
    /// 打开系统偏好设置的安全性与隐私面板
    static func openAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    /// 检查权限并返回提示信息
    static func checkPermissionAlert() -> Alert {
        return Alert(
            title: Text("需要辅助功能权限"),
            message: Text("请在系统设置中授予权限以使用快捷键功能"),
            primaryButton: .default(Text("打开设置")) {
                openAccessibilitySettings()
            },
            secondaryButton: .cancel(Text("取消"))
        )
    }
}
