//
//  URLItemEmptyStateView.swift
//  ReadItLater
//
//  Created by Codex on 2026/02/25.
//

import SwiftUI

struct URLItemEmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    init(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ZStack {
                Circle()
                    .fill(Color.appBrandPrimary.opacity(0.12))
                    .frame(width: 112, height: 112)
                    .scaleEffect(reduceMotion ? 1 : (isAnimating ? 1.06 : 0.94))

                Image(systemName: systemImage)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.appBrandPrimary)
                    .offset(y: reduceMotion ? 0 : (isAnimating ? -3 : 3))
            }
            .animation(
                reduceMotion ? .default : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                value: isAnimating
            )

            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(AppFont.screenTitle())
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus.circle.fill")
                        .font(AppFont.button())
                        .padding(.horizontal, AppSpacing.large)
                        .padding(.vertical, AppSpacing.small)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appBrandPrimary)
            }
        }
        .padding(AppSpacing.xLarge)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    URLItemEmptyStateView(
        systemImage: "tray",
        title: "Inboxは空です",
        message: "気になるURLを追加して、あとで読めるようにしましょう。",
        actionTitle: "URLを追加",
        action: {}
    )
}
