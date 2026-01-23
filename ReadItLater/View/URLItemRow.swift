//
//  URLItemRow.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI

/// リストアイテムの共通表示コンポーネント
///
/// URLItemプロトコルに準拠したモデルの共通表示ビュー
struct URLItemRow: View {
    let item: any URLItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.safeTitle)
                .font(.headline)
                .lineLimit(2)

            if let urlString = item.url {
                Text(urlString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    let container = ModelContainerFactory.createPreviewContainer()
    let exampleInbox = Inbox(url: "https://example.com", title: "Example Inbox")

    return List {
        URLItemRow(item: exampleInbox)
    }
    .modelContainer(container)
}
