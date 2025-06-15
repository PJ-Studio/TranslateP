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
            TranslateContentBGView()
            
            ScrollView {
                Text(viewModel.targetString)
                    .foregroundStyle(.white)
                    .padding()
                    .font(.system(size: viewModel.fontSize))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .shadow(radius: 4)
            }
            .frame(maxWidth: 300, maxHeight: 500)
            .scrollIndicators(.never)
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


struct TranslateContentBGView: View {
    var body: some View {
        if #available(macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(.clear)
                .shadow(radius: 4)
                .glassEffect(.regular.tint(.black.opacity(0.5)), in: .rect(cornerRadius: 4))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(.clear)
                .shadow(radius: 4)
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
