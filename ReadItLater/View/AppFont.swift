//
//  AppFont.swift
//  ReadItLater
//
//  Created by Codex on 2026/02/25.
//

import SwiftUI

enum AppFont {
    static func screenTitle() -> Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }

    static func listTitle() -> Font {
        .system(size: 17, weight: .semibold, design: .rounded)
    }

    static func body() -> Font {
        .system(.body, design: .rounded)
    }

    static func caption() -> Font {
        .system(size: 12, weight: .regular, design: .rounded)
    }

    static func button() -> Font {
        .system(.body, design: .rounded).weight(.semibold)
    }
}
