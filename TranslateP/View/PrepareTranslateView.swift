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

    var body: some View {
        HStack {
            Text("第一步：下载词典，快速翻译")
                .font(.title3)
            Button("去下载") {
                viewModel.triggerTranslation()
                buttonTapped = true
            }
        }
        .translationTask(viewModel.configuration) { session in
            if buttonTapped {
                do {
                    // Display a sheet asking the user's permission
                    // to start downloading the language pairing.
                    try await session.prepareTranslation()
                } catch {
                    // Handle any errors.
                }
            }
        }
    }
}
