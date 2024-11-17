//
//  MenuView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/16.
//

import SwiftUI

struct MenuView: View {
    @State private var hasInit = false
    @State private var targetLang: Int = 0 // 翻译前
    @State private var sourceLang: Int = 1 // 翻译后
    
    @ObservedObject var viewModel: TranslateViewModel
    
    @State private var keyboardCount = 0

    
    var body: some View {
        VStack {
            Form {
                Section("功能设置") {
                    Toggle("两次 ⌘ + C 翻译", isOn: $viewModel.keyboardEventOn)
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
                        Text("\(Int(viewModel.fontSize))pt")
                            .font(.footnote)
                            .foregroundStyle(Color.gray)
                        
                        Slider(value: $viewModel.fontSize, in: 10...40) { done in
                            if done {
                                
                            }
                        }
                        .controlSize(.small) // 修改滑杆的滑块尺寸为小样式
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
        .onAppear {
            viewModel.setupKeyboardMonitoring()
            viewModel.setupMouseMonitoring()
        }
    }
}

//#Preview {
//    MenuView()
//}
