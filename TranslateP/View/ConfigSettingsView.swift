//
//  ConfigSettingsView.swift
//  TranslateP
//
//  Created by ByteDance on 2024/11/16.
//

import SwiftUI

struct ConfigSettingsView: View {
    var body: some View {
        VStack {
            Form {
                Section("添加权限") {
                    HStack {
                        Text("给 TranslateP 添加访问“辅助功能”权限")
                            .font(.subheadline)
                        Spacer()
                        Button("去添加") {
                            Translate.openAccessibilitySettings()
                        }
                        .font(.subheadline)
                    }
                }
                .font(.headline)
                
                Section("下载字典") {
                    HStack {
                        Text("词典安装完毕后，即可使用")
                            .font(.subheadline)
                        Spacer()
                        Button("去下载") {
                            
                        }
                        .font(.subheadline)
                    }
                }
                .font(.headline)
            }
            
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
        
        .formStyle(.grouped)
    }
}

#Preview {
    ConfigSettingsView()
}
