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
    @State private var actionFeedbackTrigger = 0

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
                .urlItemListRowStyle()
            }
        }
        .urlItemListScreenStyle()
        .overlay {
            if filteredItems.isEmpty {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    URLItemEmptyStateView(
                        systemImage: "archivebox",
                        title: "Archiveは空です",
                        message: "読み終えた項目をArchiveに移すと、ここで一覧できます。"
                    )
                } else {
                    URLItemEmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "検索結果がありません",
                        message: "別のキーワードで検索するか、検索条件をクリアしてください。",
                        actionTitle: "検索をクリア",
                        action: {
                            withAnimation(.smooth) {
                                searchText = ""
                            }
                        }
                    )
                }
            }
        }
        .searchable(text: $searchText, prompt: "タイトルまたはURLで検索")
        .navigationTitle("Archive")
        .navigationDestination(for: Archive.self) { archive in
            URLItemDetailView(item: archive)
        }
        .tint(Color.appBrandPrimary)
        .sensoryFeedback(.success, trigger: actionFeedbackTrigger)
    }

    private func moveToInbox(_ archive: Archive) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToInbox(archive, using: inboxRepository)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ archive: Archive) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToBookmark(archive)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func deleteArchive(_ archive: Archive) {
        withAnimation(.bouncy) {
            repository.delete(archive)
            actionFeedbackTrigger += 1
        }
    }
}

#Preview {
    NavigationStack {
        ArchiveListView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
