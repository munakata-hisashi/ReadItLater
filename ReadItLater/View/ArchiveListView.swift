//
//  ArchiveListView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

struct ArchiveListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Archive.archivedAt, order: .reverse) private var archiveItems: [Archive]
    @State private var searchText = ""

    /// Repository（computed propertyとして生成）
    private var repository: ArchiveRepositoryProtocol {
        ArchiveRepository(modelContext: modelContext)
    }

    private var inboxRepository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    /// 検索フィルタ済みのアイテム
    private var filteredItems: [Archive] {
        archiveItems.filter { $0.matches(searchText: searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredItems) { archive in
                NavigationLink(value: archive) {
                    URLItemRow(item: archive)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    InboxSwipeButton {
                        moveToInbox(archive)
                    }
                    BookmarkSwipeButton {
                        moveToBookmark(archive)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    DeleteSwipeButton {
                        deleteArchive(archive)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "タイトルまたはURLで検索")
        .navigationTitle("Archive")
        .navigationDestination(for: Archive.self) { archive in
            URLItemDetailView(item: archive)
        }
    }

    private func moveToInbox(_ archive: Archive) {
        withAnimation {
            do {
                try repository.moveToInbox(archive, using: inboxRepository)
            } catch {
                print("Failed to move to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ archive: Archive) {
        withAnimation {
            do {
                try repository.moveToBookmark(archive)
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func deleteArchive(_ archive: Archive) {
        withAnimation {
            repository.delete(archive)
        }
    }
}

#Preview {
    NavigationStack {
        ArchiveListView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
