//
//  ScaleButtonStyle.swift
//  ReadItLater
//

import SwiftUI

/// タップ時に 0.97 倍に縮むボタンスタイル
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppAnimation.quick, value: configuration.isPressed)
    }
}
