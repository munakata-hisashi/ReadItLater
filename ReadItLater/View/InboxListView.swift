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
    @Query(sort: \Inbox.addedInboxAt, order: .reverse) private var inboxItems: [Inbox]
    @State private var showingAddSheet = false

    /// Repository（computed propertyとして生成）
    private var repository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    var body: some View {
        Group {
            if inboxItems.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "Inbox is Empty",
                    description: "URLを追加して後で読もう",
                    actionTitle: "URLを追加",
                    action: { showingAddSheet = true }
                )
            } else {
                List {
                    ForEach(inboxItems) { inbox in
                        NavigationLink(value: inbox) {
                            ArticleCardView(item: inbox)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppColors.backgroundPrimary)
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
            }
        }
        .navigationTitle("Inbox")
        .navigationDestination(for: Inbox.self) { inbox in
            URLItemDetailView(item: inbox)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Item", systemImage: "plus")
                }
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
        withAnimation(AppAnimation.standard) {
            do {
                try repository.add(url: inboxData.url, title: inboxData.title)
            } catch {
                // TODO: エラーハンドリング（アラート表示など）
                print("Failed to add to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ inbox: Inbox) {
        withAnimation(AppAnimation.standard) {
            do {
                try repository.moveToBookmark(inbox)
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func moveToArchive(_ inbox: Inbox) {
        withAnimation(AppAnimation.standard) {
            do {
                try repository.moveToArchive(inbox)
            } catch {
                print("Failed to move to Archive: \(error)")
            }
        }
    }

    private func deleteInbox(_ inbox: Inbox) {
        withAnimation(AppAnimation.standard) {
            repository.delete(inbox)
        }
    }
}

#Preview {
    NavigationStack {
        InboxListView()
    }
    .modelContainer(ModelContainerFactory.createPreviewContainer())
}
