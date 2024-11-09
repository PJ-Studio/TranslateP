//
//  PrepareTranslateView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/3.
//

import SwiftUI
import Translation

struct PrepareTranslateView: View {
    @ObservedObject var viewModel: TranslateViewModel
    @State private var buttonTapped = false
    @State private var displayString: String = "第一步：下载词典，快速翻译"
    @State private var dictDownloaded: Bool = false
    private let successDownloadString: String = "词典已下载，请进行第二步"
    
    var body: some View {
        HStack {
            Text(displayString)
                .font(.title3)
            if !dictDownloaded {
                Button("去下载") {
                    viewModel.triggerTranslation()
                    buttonTapped = true
                }
            }
        }
        .translationTask(viewModel.configuration) { session in
            if buttonTapped {
                do {
                    // Display a sheet asking the user's permission
                    // to start downloading the language pairing.
                    try await session.prepareTranslation()
                    let response = try await session.translate(successDownloadString)
                    displayString = response.targetText + "✅"
                    dictDownloaded.toggle()
                } catch {
                    // Handle any errors.
                    print(error)
                }
            }
        }
    }
}
