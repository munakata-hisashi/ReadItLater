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
    @Query(sort: \Bookmark.bookmarkedAt, order: .reverse) private var bookmarks: [Bookmark]

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
            }
        }
        .navigationTitle("Bookmarks")
        .navigationDestination(for: Bookmark.self) { bookmark in
            URLItemDetailView(item: bookmark)
        }
    }

    private func moveToInbox(_ bookmark: Bookmark) {
        withAnimation {
            do {
                try repository.moveToInbox(bookmark, using: inboxRepository)
            } catch {
                print("Failed to move to Inbox: \(error)")
            }
        }
    }

    private func moveToArchive(_ bookmark: Bookmark) {
        withAnimation {
            do {
                try repository.moveToArchive(bookmark)
            } catch {
                print("Failed to move to Archive: \(error)")
            }
        }
    }

    private func deleteBookmark(_ bookmark: Bookmark) {
        withAnimation {
            repository.delete(bookmark)
        }
    }
}

#Preview {
    NavigationStack {
        BookmarkListView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
