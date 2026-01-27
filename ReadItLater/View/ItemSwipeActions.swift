//
//  ItemSwipeActions.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/27.
//

import SwiftUI

/// ブックマークへ移動するスワイプアクションボタン
struct BookmarkSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Bookmark", systemImage: "bookmark")
        }
        .tint(.blue)
    }
}

/// アーカイブへ移動するスワイプアクションボタン
struct ArchiveSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Archive", systemImage: "archivebox")
        }
        .tint(.green)
    }
}

/// 削除するスワイプアクションボタン
struct DeleteSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Label("Delete", systemImage: "trash")
        }
    }
}

#Preview("Bookmark Button") {
    List {
        Text("Swipe left to see bookmark button")
            .swipeActions(edge: .leading) {
                BookmarkSwipeButton { }
            }
    }
}

#Preview("Archive Button") {
    List {
        Text("Swipe left to see archive button")
            .swipeActions(edge: .leading) {
                ArchiveSwipeButton { }
            }
    }
}

#Preview("Delete Button") {
    List {
        Text("Swipe right to see delete button")
            .swipeActions(edge: .trailing) {
                DeleteSwipeButton { }
            }
    }
}
