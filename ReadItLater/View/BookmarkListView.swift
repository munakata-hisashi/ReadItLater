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

    var body: some View {
        List {
            ForEach(bookmarks) { bookmark in
                NavigationLink(value: bookmark) {
                    URLItemRow(item: bookmark)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        moveToArchive(bookmark)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteBookmark(bookmark)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Bookmarks")
        .navigationDestination(for: Bookmark.self) { bookmark in
            URLItemDetailView(item: bookmark)
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
