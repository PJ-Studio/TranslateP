//
//  MenuView.swift
//  TranslateP
//
//  Created by ByteDance on 2024/11/16.
//

import SwiftUI

struct MenuView: View {
    @State private var hasInit = false
    @State private var keyboardEvent = true
    @State private var fontSize: Float = 20
    @State private var targetLang: Int = 0 // 翻译前
    @State private var sourceLang: Int = 1 // 翻译后
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack {
            Form {
                Section("功能设置") {
                    Toggle("两次 ⌘ + C 翻译", isOn: $keyboardEvent)
                        .font(.subheadline)
                    HStack {
                        Text("鼠标左键滑词翻译")
                            .font(.subheadline)
                        Spacer()
                        Text("开发中")
                            .font(.footnote)
                            .foregroundStyle(Color.gray)
                    }
                }
                .font(.headline)
                
                Section("UI 设置") {
                    HStack {
                        Text("文字大小")
                            .font(.subheadline)
                        Text("\(Int(fontSize))pt")
                            .font(.footnote)
                            .foregroundStyle(Color.gray)
                        
                        Slider(value: $fontSize, in: 14...40) { done in
                            if done {
                                
                            }
                        }
                    }
                    
//                    HStack {
//                        Picker("把", selection: $targetLang) {
//                            Text("中文").tag(0)
//                                .font(.subheadline)
//
//                            Text("英文").tag(1)
//                                .font(.subheadline)
//
//                        }
//                        
//                        .font(.subheadline)
//
//                        Picker("翻译为", selection: $sourceLang) {
//                            Text("中文").tag(0)
//                                .font(.subheadline)
//
//                            Text("英文").tag(1)
//                                .font(.subheadline)
//
//                        }
//                        .font(.subheadline)
//                    }
                }
                .font(.headline)
            }
            .formStyle(.grouped)
            
            HStack {
                Spacer()
                Text("软件版本：1.0")
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: "http://pjhubs.com")!)
                    }
            }
            Spacer()
        }
    }
}

#Preview {
    MenuView()
}
