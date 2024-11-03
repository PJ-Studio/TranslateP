//
//  TranslatePApp.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/2.
//

import SwiftUI
import Carbon.HIToolbox
import AppKit
import Translation

@main
struct TranslatePApp: App {
    @StateObject var viewModel = TranslateViewModel()
    @State private var showingPermissionAlert = false
    @State private var hasPermission = Translate.hasShortcutPermission()

    var body: some Scene {
        WindowGroup(id: Translate.translateWindow) {
            if hasPermission {
                TranslateView(viewModel: viewModel)
            } else {
                SettingsView(viewModel: viewModel)
                    .frame(minWidth: 400,
                           maxWidth: 400,
                           minHeight: 150,
                           maxHeight: 150,
                           alignment: .center)
                    .onAppear {
                        if !hasPermission {
                            showingPermissionAlert = true
                        }
                        
                        // 创建定时器每秒检查权限状态
                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                            hasPermission = Translate.hasShortcutPermission()
                        }
                    }
            }
        }
        .windowResizability(.contentSize)
    }
}
