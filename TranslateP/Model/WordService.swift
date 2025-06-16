//
//  WordService.swift
//  TranslateP
//
//  Created by pjhubs on 2025/6/16.
//

import Foundation
import CoreServices

struct WordService {
    static func getWordPhonetics(for word: String) -> String? {
        let range = CFRangeMake(0, word.count)
        
        guard let unmanagedDefinition = DCSCopyTextDefinition(nil, word as CFString, range) else {
            return nil
        }
        
        let definition = unmanagedDefinition.takeRetainedValue() as String
        
        // 按 | 分割字符串
        let components = definition.components(separatedBy: "|")
        
        // 音标在第一个 | 之后第二个 | 之前（索引为1）
        guard components.count >= 2 else {
            return nil
        }
        
        let phonetics = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return phonetics.isEmpty ? nil : "[" + phonetics + "]"
    }
}
