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
    func save(source: String, target: String, phonetic: String?, targetLanguage: String, to folderURL: URL) {
        let fileName = "\(targetLanguage).md"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        let dateString = dateFormatter.string(from: Date())
        
        // 构建新单词内容
        let newContent = """
        
        ### \(source)
        - 音标: \(phonetic ?? "无")
        - 译文: \(target)
        """
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            var fileContent = ""
            if FileManager.default.fileExists(atPath: fileURL.path) {
                fileContent = try String(contentsOf: fileURL, encoding: .utf8)
            }
            
            // 检查今天日期的 section 是否存在
            let dateHeader = "# \(dateString)"
            
            if !fileContent.contains(dateHeader) {
                // 如果文件不为空且最后没有换行，加两个换行
                if !fileContent.isEmpty {
                    if !fileContent.hasSuffix("\n\n") {
                         if fileContent.hasSuffix("\n") {
                             fileContent += "\n"
                         } else {
                             fileContent += "\n\n"
                         }
                    }
                }
                fileContent += "\(dateHeader)\n"
            }
            
            fileContent += newContent
            
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("保存单词本失败: \(error)")
        }
    }
    
    /// 从文件夹加载特定语言的单词本
    func load(from folderURL: URL, targetLanguage: String) -> [WordEntry] {
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
                currentPhonetic = String(trimmedLine.dropFirst(6))
            } else if trimmedLine.hasPrefix("- 译文: ") {
                currentTarget = String(trimmedLine.dropFirst(6))
            }
        }
        
        // 循环结束后保存最后一个单词
        saveCurrentEntry()
        
        // 按日期倒序排列（最近的在前面）
        return entries.sorted { $0.date > $1.date }
    }
    
    /// 删除单词（重新写入文件）
    func delete(entry: WordEntry, from folderURL: URL, targetLanguage: String) {
        // 加载当前所有单词
        var allEntries = load(from: folderURL, targetLanguage: targetLanguage)
        
        // 删除指定单词
        allEntries.removeAll { $0 == entry }
        
        // 重写文件
        let fileName = "\(targetLanguage).md"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        var fileContent = ""
        
        // 按日期分组
        let grouped = Dictionary(grouping: allEntries, by: { dateFormatter.string(from: $0.date) })
        // 按日期升序排列写入文件，保持从旧到新的日志风格
        let sortedDatesAsc = grouped.keys.sorted()
        
        for (index, dateString) in sortedDatesAsc.enumerated() {
            if index > 0 {
                fileContent += "\n\n"
            }
            fileContent += "# \(dateString)\n"
            if let entriesForDate = grouped[dateString] {
                for word in entriesForDate {
                    fileContent += "\n### \(word.source)\n"
                    fileContent += "- 音标: \(word.phonetic ?? "无")\n"
                    fileContent += "- 译文: \(word.target)" // 避免多余换行
                }
            }
        }
        // 最后加个换行
        fileContent += "\n"
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("删除单词失败: \(error)")
        }
    }
}
