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
