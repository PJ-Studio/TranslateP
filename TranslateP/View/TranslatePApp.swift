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
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    var body: some Scene {
        MenuBarExtra("App", systemImage: "translate") {
            MenuView(viewModel: viewModel)
                .onAppear {
                    viewModel.openWindowAction = openWindow
                    viewModel.dismissWindowAction = dismissWindow
                    NSApplication.shared.setActivationPolicy(.accessory)
                }
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentSize)

        Window("文案翻译", id: Translate.translateWindow) {
            TranslateContentView(viewModel: viewModel)
        }
        .windowStyle(.plain) // 设置 window 类型为只有内容，其他都不要
        .windowLevel(.floating)
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        
        Window("单词本", id: Translate.wordBookWindow) {
            WordBookView()
                .frame(minWidth: 500, minHeight: 400)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
    }
}
