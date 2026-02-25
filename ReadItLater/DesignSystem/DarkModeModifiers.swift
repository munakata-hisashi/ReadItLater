//
//  DarkModeModifiers.swift
//  ReadItLater
//

import SwiftUI

extension View {
    /// ライトモードでは通常の影、ダークモードではカラードグロー + ボーダーを適用する影
    @ViewBuilder
    func adaptiveShadow(color: Color = AppColors.brandPrimary, radius: CGFloat = 6) -> some View {
        modifier(AdaptiveShadowModifier(color: color, radius: radius))
    }
}

private struct AdaptiveShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.2), radius: radius * 1.5, x: 0, y: 0)
        } else {
            content
                .shadow(color: .black.opacity(0.06), radius: radius, x: 0, y: 2)
        }
    }
}
