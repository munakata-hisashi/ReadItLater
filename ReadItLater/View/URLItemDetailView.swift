//
//  URLItemDetailView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

/// URLItemプロトコルを活用した汎用詳細画面
///
/// Inbox、Bookmark、Archiveの詳細表示に使用する共通ビュー
struct URLItemDetailView: View {
    let item: any URLItem
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack {
            if let url = item.maybeURL {
                WebView(url: url)
            } else {
                VStack {
                    Text(item.safeTitle)
                    Text("No URL")
                }
            }
        }
        .navigationTitle(item.safeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if let url = item.maybeURL {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openURL(url)
                    } label: {
                        Label("ブラウザで開く", systemImage: "safari")
                    }
                }
            }
        }
    }
}

#Preview {
    let container = ModelContainerFactory.createPreviewContainer()
    let exampleBookmark = Bookmark(
        url: "https://example.com",
        title: "Example",
        addedInboxAt: Date.now
    )

    return NavigationStack {
        URLItemDetailView(item: exampleBookmark)
    }
    .modelContainer(container)
}
