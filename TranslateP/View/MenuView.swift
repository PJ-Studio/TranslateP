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
    @State private var sourceLang: Int = 0 // 翻译后
    
    @ObservedObject var viewModel: TranslateViewModel
    
    @State private var keyboardCount = 0

    
    var body: some View {
        VStack {
            Form {
                Section("功能设置") {
                    Toggle("两次 ⌘ + C 翻译", isOn: $viewModel.keyboardEventOn)
                        .font(.subheadline)
                    
                    HStack {
                        Picker("", selection: $targetLang) {
                            Text("英文").tag(0)
                                .font(.subheadline)
                        }
                        .font(.subheadline)
                        .frame(width: 100)
                        .padding(EdgeInsets(top: 0, leading: -15, bottom: 0, trailing: 20))
                        
                        Picker(selection: $sourceLang) {
                            Text("中文").tag(0)
                                .font(.subheadline)
                        } label: {
                            Image(systemName: "arrowshape.right")
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                    }
                    .foregroundStyle(Color.gray)
                    
//                    VStack {
//                        Toggle("截图翻译", isOn: $viewModel.screenshotEventOn)
//                            .font(.subheadline)
//                        HStack {
//                            Text("为防止误操作，推荐用完即关")
//                                .font(.footnote)
//                                .foregroundStyle(Color.secondary)
//                            Spacer()
//                        }
//                    }
                    
//                    HStack {
//                        Text("鼠标左键滑词翻译")
//                            .font(.subheadline)
//                        Spacer()
//                        Text("开发中")
//                            .font(.footnote)
//                            .foregroundStyle(Color.gray)
//                    }
                    
                }
                .font(.headline)
                
                Section("UI 设置") {
                    HStack {
                        Text("文字大小")
                            .font(.subheadline)
                        Text("\(Int(viewModel.fontSize))pt")
                            .foregroundStyle(Color.gray)
                            .font(.footnote)
                        
                        Slider(value: $viewModel.fontSize, in: 10...40) { done in
                            if done {
                                
                            }
                        }
                        .controlSize(.small) // 修改滑杆的滑块尺寸为小样式
                    }
                }
                .font(.headline)
            }
            .formStyle(.grouped)
            
            HStack {
                Group {
                    Image(systemName: "power")
                    
                    Text("退出")
                        .onTapGesture {
                            NSApplication.shared.terminate(nil)
                        }
                        .padding(EdgeInsets(top: 0, leading: -25, bottom: 0, trailing: 0))
                }
                .font(.footnote)
                .foregroundStyle(Color.gray)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))

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

#Preview {
    MenuView(viewModel: TranslateViewModel())
        .frame(width: 300)
}
