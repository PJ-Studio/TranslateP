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
    static let wordBookWindow = "word_book_window"
    
    /// 单词本更新通知
    static let wordBookDidUpdate = Notification.Name("wordBookDidUpdate")
    
    /// 标记是否下载过词典
    static let hasDownloadedDict = "has_downloaded_dict"
    
    /// 自动保存到单词本开关
    static let autoSaveToWordBook = "auto_save_to_word_book"
    /// 两次 cmd+c 触发翻译的时间间隔
    static let doubleCopyInterval = "double_copy_interval"
    /// 单词本路径
    static let wordBookPath = "word_book_path"
    
    static func findWindow(_ identifier: String) -> NSWindow? {
        return NSApplication.shared.windows.filter({ ($0.identifier?.rawValue ?? "").contains(identifier)}).first
    }
    
    static func wordBookFolderURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let folderURL = (base ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("TranslateP", isDirectory: true)
            .appendingPathComponent("WordBook", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            return FileManager.default.temporaryDirectory
                .appendingPathComponent("TranslateP", isDirectory: true)
                .appendingPathComponent("WordBook", isDirectory: true)
        }
        
        return folderURL
    }
}
