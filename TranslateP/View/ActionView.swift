//
//  ContentView.swift
//  TranslateP
//
//  Created by ByteDance on 2024/11/2.
//

import SwiftUI

struct ActionView: View {
    var body: some View {
        List {
            SearchActionView()
            QuitActionView()
        }
    }
}
