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
    @State private var isArrowFlipped = false // 箭头翻转动画状态
    
    /// 从 Bundle 获取应用版本号
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }

    
    var body: some View {
        VStack {
            Form {
                Section("功能设置") {
                    Toggle("两次 ⌘ + C 翻译", isOn: $viewModel.keyboardEventOn)
                        .font(.subheadline)
                    
                    Toggle("剪贴板截图翻译", isOn: $viewModel.clipboardSnapshotOn)
                        .font(.subheadline)
                    
                    HStack {
                        // 固定显示英文
                        Text("英文")
                            .font(.subheadline)
                            .frame(width: 60, alignment: .leading)
                            .padding(EdgeInsets(top: 0, leading: -10, bottom: 0, trailing: 0))
                        
                        Spacer()
                        
                        // 箭头按钮（可点击反转）
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isArrowFlipped.toggle()
                                viewModel.toggleLanguageDirection()
                            }
                        }) {
                            Image(systemName: "arrowshape.right")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .scaleEffect(x: viewModel.isLanguageReversed ? -1 : 1, y: 1)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.isLanguageReversed)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // 固定显示中文
                        Text("中文")
                            .font(.subheadline)
                            .frame(width: 60, alignment: .trailing)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -10))
                    }
                    .padding(.horizontal, 10)
                    
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
                            .font(.footnote)
                        
                        Slider(value: $viewModel.fontSize, in: 10...40)
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
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))

                Spacer()
                
                Text("软件版本：\(appVersion)")
                    .font(.footnote)
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
