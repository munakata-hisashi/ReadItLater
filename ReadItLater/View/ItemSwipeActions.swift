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
            SwipeActionIconLabel(title: "Bookmark", systemImage: "bookmark")
        }
        .tint(.blue)
    }
}

/// アーカイブへ移動するスワイプアクションボタン
struct ArchiveSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SwipeActionIconLabel(title: "Archive", systemImage: "archivebox")
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

private struct SwipeActionIconLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.iconOnly)
            .overlay(alignment: .bottom) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }
            .frame(width: 68, height: 72, alignment: .top)
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
