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
                        Text(viewModel.permissionDisplayString)
                            .font(.subheadline)
                        Spacer()
                        if !viewModel.hasPermission {
                            Button("去添加") {
                                Translate.openAccessibilitySettings()
                            }
                            .font(.subheadline)
                        }
                    }
                }
                .font(.headline)
                
                Section("2. 下载词典") {
                    HStack {
                        Text(viewModel.dictDisplayString)
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
        }
        .formStyle(.grouped)
        .onAppear {
            viewModel.hasPermission = Translate.hasShortcutPermission()
            if viewModel.hasPermission {
                viewModel.permissionDisplayString = "已添加权限 ✅"
            }
        }
    }
}

#Preview {
    var viewModel = TranslateViewModel()
    ConfigSettingsView(viewModel: viewModel)
}
