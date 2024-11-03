//
//  QuitActionView.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/2.
//

import SwiftUI

struct QuitActionView: View {
    var body: some View {
        Text("退出")
            .onTapGesture {
                NSApplication.shared.terminate(nil)
            }
    }
}

#Preview {
    QuitActionView()
}
