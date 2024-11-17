//
//  DownloadDictView.swift
//  TranslateP
//
//  Created by ByteDance on 2024/11/17.
//

import SwiftUI

struct DownloadDictView: View {
    @ObservedObject var viewModel: TranslateViewModel
    
    
    var body: some View {
        VStack {
            Text("字典下载中...")
                .padding()
                .onAppear {
                    viewModel.triggerTranslation()
                }
                .translationTask(viewModel.configuration) { session in
                    do {
                        // Display a sheet asking the user's permission
                        // to start downloading the language pairing.
                        try await session.prepareTranslation()
                        let response = try await session.translate(viewModel.successDownloadString)
                        viewModel.dictDisplayString = response.targetText + " ✅"
                        viewModel.dictDownloaded.toggle()
                        viewModel.dismissDownloadDictWindow()
                    } catch {
                        // Handle any errors.
                        print(error)
                    }
                }
            
            Button("重试") {
                viewModel.triggerTranslation()
            }
        }
    }
}

#Preview {
    DownloadDictView(viewModel: TranslateViewModel())
}
