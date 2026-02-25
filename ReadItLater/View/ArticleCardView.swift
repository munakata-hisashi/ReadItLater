//
//  ArticleCardView.swift
//  ReadItLater
//

import SwiftUI

/// カード型記事表示コンポーネント
///
/// URLItemプロトコルに準拠したモデルをカード形式で表示する
struct ArticleCardView: View {
    let item: any URLItem
    @State private var didTap = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Text(item.safeTitle)
                .font(AppFont.headline())
                .lineLimit(2)
                .foregroundColor(.primary)

            if let urlString = item.url {
                Text(urlString)
                    .font(AppFont.caption())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .sensoryFeedback(.selection, trigger: didTap)
        .onTapGesture { didTap.toggle() }
    }
}

#Preview {
    let container = ModelContainerFactory.createPreviewContainer()
    let exampleInbox = Inbox(url: "https://example.com", title: "Example Article Title That Is Quite Long")

    return List {
        ArticleCardView(item: exampleInbox)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(AppColors.backgroundPrimary)
    .modelContainer(container)
}
