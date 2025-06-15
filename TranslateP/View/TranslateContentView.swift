//
//  TranslateContentView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/17.
//

import SwiftUI

struct TranslateContentView: View {
    @ObservedObject var viewModel: TranslateViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            TranslateContentBGView()
            
            ScrollView {
                Text(viewModel.targetString)
                    .padding()
                    .font(.system(size: viewModel.fontSize))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .foregroundStyle((colorScheme == .dark ? Color.white : Color.black).opacity(0.7))
            .shadow(radius: 4)
    }
}

#Preview {
    var viewModel = TranslateViewModel()
    
    ZStack {
        Text("333")
        TranslateContentView(viewModel: viewModel)
    }
}
