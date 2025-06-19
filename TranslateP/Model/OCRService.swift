//
//  OCRService.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/16.
//

import Foundation
import Vision
import AppKit

class OCRService: ObservableObject {
    
    /// 使用Vision框架识别图片中的文字
    /// - Parameters:
    ///   - image: 需要识别的图片
    ///   - completion: 识别完成的回调，返回识别出的文字或错误信息
    static func recognizeText(from image: NSImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("OCR识别错误: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(nil)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }
                
                let finalText = recognizedStrings.joined(separator: "\n")
                completion(finalText.isEmpty ? nil : finalText)
            }
        }
        
        // 设置识别级别为准确（accurate）以获得更好的识别效果
        request.recognitionLevel = .accurate
        
        // 支持多种语言识别
        request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"]
        
        // 自动语言识别
        request.automaticallyDetectsLanguage = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    print("OCR处理错误: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
} 