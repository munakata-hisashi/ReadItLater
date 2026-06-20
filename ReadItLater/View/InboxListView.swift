//
//  InboxListView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

struct InboxListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<URLItem> { $0.status == "inbox" },
        sort: \URLItem.addedInboxAt,
        order: .reverse
    ) private var inboxItems: [URLItem]
    @State private var showingAddSheet = false
    @State private var addButtonTrigger = 0
    @State private var actionFeedbackTrigger = 0

    /// Repository（computed propertyとして生成）
    private var repository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    var body: some View {
        List {
            ForEach(inboxItems) { inbox in
                NavigationLink(value: inbox) {
                    URLItemRow(item: inbox)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    BookmarkSwipeButton {
                        moveToBookmark(inbox)
                    }
                    ArchiveSwipeButton {
                        moveToArchive(inbox)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    DeleteSwipeButton {
                        deleteInbox(inbox)
                    }
                }
                .urlItemListRowStyle()
            }
        }
        .urlItemListScreenStyle()
        .overlay {
            if inboxItems.isEmpty {
                URLItemEmptyStateView(
                    systemImage: "tray",
                    title: "Inboxはまだ空です",
                    message: "気になる記事URLを追加して、あとで読み返せるようにしましょう。",
                    actionTitle: "URLを追加",
                    action: openAddSheet
                )
            }
        }
        .navigationTitle("Inbox")
        .navigationDestination(for: URLItem.self) { inbox in
            URLItemDetailView(item: inbox)
        }
        .tint(Color.appBrandPrimary)
        .sensoryFeedback(.success, trigger: actionFeedbackTrigger)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: openAddSheet) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.appBrandPrimary))
                        .symbolEffect(.bounce, value: addButtonTrigger)
                }
                .contentShape(Rectangle())
                .accessibilityLabel("Add Item")
                .accessibilityHint("Open sheet to add a new URL")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddInboxSheet(
                onSave: { inboxData in
                    addToInbox(from: inboxData)
                    showingAddSheet = false
                },
                onCancel: {
                    showingAddSheet = false
                }
            )
        }
    }

    private func addToInbox(from inboxData: InboxData) {
        withAnimation(.bouncy) {
            do {
                try repository.add(url: inboxData.url, title: inboxData.title)
                actionFeedbackTrigger += 1
            } catch {
                // TODO: エラーハンドリング（アラート表示など）
                print("Failed to add to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ inbox: URLItem) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToBookmark(inbox)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func moveToArchive(_ inbox: URLItem) {
        withAnimation(.bouncy) {
            do {
                try repository.moveToArchive(inbox)
                actionFeedbackTrigger += 1
            } catch {
                print("Failed to move to Archive: \(error)")
            }
        }
    }

    private func deleteInbox(_ inbox: URLItem) {
        withAnimation(.bouncy) {
            repository.delete(inbox)
            actionFeedbackTrigger += 1
        }
    }

    private func openAddSheet() {
        addButtonTrigger += 1
        showingAddSheet = true
    }
}

#Preview {
    NavigationStack {
        InboxListView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
