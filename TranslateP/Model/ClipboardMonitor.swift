//
//  ClipboardMonitor.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/16.
//

import Foundation
import AppKit

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    var onImageDetected: ((NSImage) -> Void)?
    
    /// 开始监听剪贴板
    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    /// 停止监听剪贴板
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        // 检查剪贴板内容是否发生变化
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // 检查是否包含图片
            if let image = getImageFromPasteboard() {
                onImageDetected?(image)
            }
        }
    }
    
    /// 从剪贴板获取图片
    private func getImageFromPasteboard() -> NSImage? {
        let pasteboard = NSPasteboard.general
        
        // 检查是否有图片数据，支持更多格式
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png, .tiff,
            NSPasteboard.PasteboardType("public.jpeg"),  // JPEG格式
            NSPasteboard.PasteboardType("com.compuserve.gif"),  // GIF格式
            NSPasteboard.PasteboardType("public.heif"),  // HEIF格式
            NSPasteboard.PasteboardType("com.adobe.pdf") // PDF格式
        ]
        
        for type in imageTypes {
            if let imageData = pasteboard.data(forType: type) {
                if let image = NSImage(data: imageData) {
                    return image
                }
            }
        }
        
        // 检查是否有文件路径指向图片
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            for url in fileURLs {
                // 检查文件扩展名是否为图片格式
                let imageExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "webp", "heif", "heic", "pdf"]
                if imageExtensions.contains(url.pathExtension.lowercased()) {
                    if let image = NSImage(contentsOf: url) {
                        return image
                    }
                }
            }
        }
        
        return nil
    }
    
    deinit {
        stopMonitoring()
    }
} 