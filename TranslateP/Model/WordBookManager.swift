//
//  WordBookManager.swift
//  TranslateP
//
//  Created by TranslateP on 2024/11/04.
//

import Foundation

struct WordEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    let source: String
    let target: String
    let phonetic: String?
    let date: Date
    
    // Ignore ID for equality check since it's transient
    static func == (lhs: WordEntry, rhs: WordEntry) -> Bool {
        return lhs.source == rhs.source &&
               lhs.target == rhs.target &&
               lhs.phonetic == rhs.phonetic &&
               Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
    }
}

class WordBookManager {
    static let shared = WordBookManager()
    
    private init() {}
    
    private let queue = DispatchQueue(label: "com.translatep.wordbookmanager.queue")
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// 获取单词本文件夹下的所有语言文件（不含扩展名）
    func getAvailableLanguages(from folderURL: URL) -> [String] {
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension == "md" }
                           .map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            print("获取语言列表失败: \(error)")
            return []
        }
    }
    
    /// 保存单词到对应的 Markdown 文件
    func save(source: String, target: String, phonetic: String?, targetLanguage: String, to folderURL: URL) {        queue.sync {
            // 先加载现有内容
            var entries = loadInternal(from: folderURL, targetLanguage: targetLanguage)
            
            // 创建新条目
            let dateString = dateFormatter.string(from: Date())
            let todayDate = dateFormatter.date(from: dateString) ?? Date()
            
            let newEntry = WordEntry(source: source, target: target, phonetic: phonetic, date: todayDate)
            
            // 插入到最前面
            entries.insert(newEntry, at: 0)
            
            // 生成文件内容
            let fileContent = generateFileContent(from: entries)
            
            // 写入文件
            let fileName = "\(targetLanguage).md"
            let fileURL = folderURL.appendingPathComponent(fileName)
            
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("保存单词本失败: \(error)")
            }
        }
    }
    
    private func loadInternal(from folderURL: URL, targetLanguage: String) -> [WordEntry] {
        let fileName = "\(targetLanguage).md"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }
        
        var entries: [WordEntry] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentDate: Date?
        var currentSource: String?
        var currentPhonetic: String?
        var currentTarget: String?
        
        // 辅助函数：保存当前解析的单词
        func saveCurrentEntry() {
            if let source = currentSource, let target = currentTarget, let date = currentDate {
                entries.append(WordEntry(source: source, target: target, phonetic: currentPhonetic, date: date))
            }
        }
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("# ") {
                // 如果遇到新日期，先保存之前的单词
                saveCurrentEntry()
                
                // 重置当前单词状态
                currentSource = nil
                currentPhonetic = nil
                currentTarget = nil
                
                let dateString = String(trimmedLine.dropFirst(2))
                currentDate = dateFormatter.date(from: dateString)
            } else if trimmedLine.hasPrefix("### ") {
                // 如果遇到新单词，先保存之前的单词
                saveCurrentEntry()
                
                // 开始新单词
                currentSource = String(trimmedLine.dropFirst(4))
                currentPhonetic = nil
                currentTarget = nil
            } else if trimmedLine.hasPrefix("- 音标: ") {
                let phon = String(trimmedLine.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                currentPhonetic = (phon.isEmpty || phon == "无") ? nil : phon
            } else if trimmedLine.hasPrefix("- 译文: ") {
                currentTarget = String(trimmedLine.dropFirst(6))
            }
        }
        
        // 循环结束后保存最后一个单词
        saveCurrentEntry()
        
        return entries
    }
    
    /// 从文件夹加载特定语言的单词本
    func load(from folderURL: URL, targetLanguage: String) -> [WordEntry] {
        return queue.sync {
            return loadInternal(from: folderURL, targetLanguage: targetLanguage)
        }
    }
    
    /// 删除单词（重新写入文件）
    func delete(entry: WordEntry, from folderURL: URL, targetLanguage: String) {
        queue.sync {
            // 加载当前所有单词
            var allEntries = loadInternal(from: folderURL, targetLanguage: targetLanguage)
            
            // 删除指定单词
            allEntries.removeAll { $0 == entry }
            
            let fileName = "\(targetLanguage).md"
            let fileURL = folderURL.appendingPathComponent(fileName)
            
            // 如果没有剩余单词，直接删除文件
            if allEntries.isEmpty {
                do {
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.removeItem(at: fileURL)
                    }
                } catch {
                    print("删除单词本文件失败: \(error)")
                }
                return
            }
            
            // 重写文件
            
            let fileContent = generateFileContent(from: allEntries)
            
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("删除单词失败: \(error)")
            }
        }
    }
    
    private func generateFileContent(from entries: [WordEntry]) -> String {
        var fileContent = ""
        
        // 按日期分组
        let grouped = Dictionary(grouping: entries, by: { dateFormatter.string(from: $0.date) })
        let sortedDatesDesc = grouped.keys.sorted(by: >)
        
        for (index, dateString) in sortedDatesDesc.enumerated() {
            if index > 0 {
                fileContent += "\n\n"
            }
            fileContent += "# \(dateString)\n"
            if let entriesForDate = grouped[dateString] {
                for word in entriesForDate {
                    fileContent += "\n### \(word.source)\n"
                    if let phon = word.phonetic, !phon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        fileContent += "- 音标: \(phon)\n"
                    }
                    fileContent += "- 译文: \(word.target)"
                }
            }
        }
        // 最后加个换行
        fileContent += "\n"
        
        return fileContent
    }
}
