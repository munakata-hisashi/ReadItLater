//
//  ItemSwipeActions.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/27.
//

import SwiftUI

/// Inboxへ移動するスワイプアクションボタン
struct InboxSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Inbox", systemImage: "tray")
        }
        .tint(Color.appSwipeInbox)
        .accessibilityLabel("Move to Inbox")
    }
}

/// ブックマークへ移動するスワイプアクションボタン
struct BookmarkSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SwipeActionIconLabel(title: "Bookmark", systemImage: "bookmark")
        }
        .tint(Color.appSwipeBookmark)
        .accessibilityLabel("Move to Bookmark")
    }
}

/// アーカイブへ移動するスワイプアクションボタン
struct ArchiveSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SwipeActionIconLabel(title: "Archive", systemImage: "archivebox")
        }
        .tint(Color.appSwipeArchive)
        .accessibilityLabel("Move to Archive")
    }
}

/// 削除するスワイプアクションボタン
struct DeleteSwipeButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Label("Delete", systemImage: "trash")
        }
        .accessibilityLabel("Delete item")
    }
}

#Preview("Inbox Button") {
    List {
        Text("Swipe left to see inbox button")
            .swipeActions(edge: .leading) {
                InboxSwipeButton { }
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
