//
//  EmptyStateView.swift
//  ReadItLater
//

import SwiftUI

/// 空状態表示コンポーネント
///
/// ContentUnavailableView ベース。パルスアニメーション付きアイコンと
/// グラデーション CTA ボタンを持つ。
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isPulsing ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear { isPulsing = true }

            VStack(spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppFont.title2())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(AppFont.body())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.large)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.headline())
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.xLarge)
                        .padding(.vertical, AppSpacing.small)
                        .background(
                            LinearGradient(
                                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: AppColors.brandPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
    }
}

#Preview("空状態 with ボタン") {
    EmptyStateView(
        icon: "tray",
        title: "Inbox is Empty",
        description: "URLを追加して後で読もう",
        actionTitle: "URLを追加",
        action: {}
    )
}

#Preview("空状態 without ボタン") {
    EmptyStateView(
        icon: "bookmark",
        title: "No Bookmarks",
        description: "InboxのURLをブックマークに移動できます"
    )
}

#Preview("検索結果なし") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No Results",
        description: "\"swift\" に一致するアイテムが見つかりません"
    )
}
