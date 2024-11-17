//
//  ConfigSettingsView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/16.
//

import SwiftUI

struct ConfigSettingsView: View {
    @ObservedObject var viewModel: TranslateViewModel
    
    var body: some View {
        VStack {
            Form {
                Section("1. 添加权限") {
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
                
                Section("2. 下载词典") {
                    HStack {
                        Text(viewModel.displayString)
                            .font(.subheadline)
                        Spacer()
                        
                        if !viewModel.dictDownloaded {
                            Button("去下载") {
                                viewModel.openDownloadDictWindow()
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .font(.headline)
            }
            
            HStack {
                Spacer()
                Button("下一步") {
                    viewModel.hasPermission = Translate.hasShortcutPermission()
                }
                .font(.subheadline)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 30))

            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    var viewModel = TranslateViewModel()
    ConfigSettingsView(viewModel: viewModel)
}
