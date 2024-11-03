//
//  SettingsView.swift
//  TranslateP
//
//  Created by ByteDance on 2024/11/3.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TranslateViewModel
    
    var body: some View {
        VStack {
            HStack {
                if !Translate.hasShortcutPermission() {
                    HStack {
                        Text("‼️ 请授权 TranslateP 监听快捷键权限")
                            .font(.headline)
                        Button("去授权") {
                            Translate.openAccessibilitySettings()
                        }
                    }
                }
            }
            .padding()
            Text("授权开启后功能自动生效，光标划选你想要翻译的内容")
                .foregroundStyle(.secondary)
            Text("执行两次 command + c 即可")
                .foregroundStyle(.secondary)
            
            HStack {
                Spacer()
                Image(systemName: "info.circle")
                    .padding()
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: "http://pjhubs.com")!)
                    }
            }
        }
    }
}
