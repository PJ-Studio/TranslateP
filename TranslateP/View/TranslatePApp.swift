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
//    @StateObject var viewModel = TranslateViewModel()
//    @State private var showingPermissionAlert = false
    @State private var hasPermission = Translate.hasShortcutPermission()

    var body: some Scene {
        MenuBarExtra("App", systemImage: "translate") {
            if hasPermission {
                MenuView()
            } else {
                ConfigSettingsView()
            }
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)

//        Window("配置页", id: Translate.settingsWindow) {
//            ConfigSettingsView()
//        }
        
//        WindowGroup(id: Translate.translateWindow) {
//            if hasPermission {
//                TranslateView(viewModel: viewModel)
//            } else {
//                SettingsView(viewModel: viewModel)
//                    .frame(minWidth: 400,
//                           maxWidth: 400,
//                           minHeight: 200,
//                           maxHeight: 200,
//                           alignment: .center)
//                    .onAppear {
//                        if !hasPermission {
//                            showingPermissionAlert = true
//                        }
//                        
//                        // 创建定时器每秒检查权限状态
//                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//                            hasPermission = Translate.hasShortcutPermission()
//                        }
//                    }
//            }
//        }
//        .windowResizability(.contentSize)
    }
}
