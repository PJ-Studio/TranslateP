//
//  Translate.swift
//  TranslateP
//
//  Created by pjhubs on 2024/11/3.
//

import AppKit
import SwiftUI

struct Translate {
    static let translateWindow = "translate_window"
    
    static func findWindow(_ identifier: String) -> NSWindow? {
        return NSApplication.shared.windows.filter({ ($0.identifier?.rawValue ?? "").contains(identifier)}).first
    }
}
