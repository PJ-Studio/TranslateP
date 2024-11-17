//
//  TranslateContentView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/17.
//

import SwiftUI

struct TranslateContentView: View {
    @ObservedObject var viewModel: TranslateViewModel

    var body: some View {
        VStack {
            Text(viewModel.targetString)
                .fixedSize()
        }
        .padding()
        .background {
            Rectangle()
                .foregroundStyle(Color.gray)
        }
        .translationTask(viewModel.configuration) { session in
            do {
                let resp = try await session.translate(viewModel.sourceString)
                DispatchQueue.main.async {
                    viewModel.targetString = resp.targetText
                }
            } catch {
                print("翻译错误: \(error)")
            }
        }
    }
}

//#Preview {
//    TranslateContentView()
//}
