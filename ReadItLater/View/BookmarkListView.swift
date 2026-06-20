//
//  BookmarkListView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

struct BookmarkListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<URLItem> { $0.status == "bookmark" },
        sort: \URLItem.bookmarkedAt,
        order: .reverse
    ) private var bookmarks: [URLItem]
    @State private var actionFeedbackTrigger = 0

    /// Repository（computed propertyとして生成）
    private var repository: BookmarkRepositoryProtocol {
        BookmarkRepository(modelContext: modelContext)
    }

    private var inboxRepository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    var body: some View {
        List {
            ForEach(bookmarks) { bookmark in
                NavigationLink(value: bookmark) {
                    URLItemRow(item: bookmark)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    InboxSwipeButton {
                        moveToInbox(bookmark)
                    }
                    ArchiveSwipeButton {
                        moveToArchive(bookmark)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    DeleteSwipeButton {
                        deleteBookmark(bookmark)
                    }
                }
                .urlItemListRowStyle()
            }
        }
        .urlItemListScreenStyle()
        .overlay {
            if bookmarks.isEmpty {
                URLItemEmptyStateView(
                    systemImage: "bookmark",
                    title: "Bookmarkは空です",
                    message: "Inboxから気になる項目をBookmarkすると、ここに表示されます。"
                )
            }
        }
        .navigationTitle("Bookmarks")
        .navigationDestination(for: URLItem.self) { bookmark in
            URLItemDetailView(item: bookmark)
        }
        .tint(Color.appBrandPrimary)
        .sensoryFeedback(.success, trigger: actionFeedbackTrigger)
    }

    private func moveToInbox(_ bookmark: URLItem) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToInbox(bookmark, using: inboxRepository)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Inbox: \(error)")
            }
        }
    }

    private func moveToArchive(_ bookmark: URLItem) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToArchive(bookmark)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Archive: \(error)")
            }
        }
    }

    private func deleteBookmark(_ bookmark: URLItem) {
        withAnimation(.bouncy) {
            repository.delete(bookmark)
            actionFeedbackTrigger += 1
        }
    }
}

#Preview {
    NavigationStack {
        BookmarkListView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
