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
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(.background)
                .shadow(radius: 4)
            
            ScrollView {
                Text(viewModel.targetString)
                    .padding()
                    .font(.system(size: viewModel.fontSize))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: 300, maxHeight: 500)
            .scrollIndicators(.hidden)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(lineWidth: 0.5)
                    .opacity(0.3)
            }
        }
        .fixedSize()
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

#Preview {
    var viewModel = TranslateViewModel()
    
    ZStack {
        Text("333")
        TranslateContentView(viewModel: viewModel)
    }
}
