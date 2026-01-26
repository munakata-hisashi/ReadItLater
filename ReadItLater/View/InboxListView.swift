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
        List {
            ForEach(inboxItems) { inbox in
                NavigationLink(value: inbox) {
                    URLItemRow(item: inbox)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        moveToBookmark(inbox)
                    } label: {
                        Label("Bookmark", systemImage: "bookmark")
                    }
                    .tint(.blue)

                    Button {
                        moveToArchive(inbox)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteInbox(inbox)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
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
        withAnimation {
            do {
                try repository.add(url: inboxData.url, title: inboxData.title)
            } catch {
                // TODO: エラーハンドリング（アラート表示など）
                print("Failed to add to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ inbox: Inbox) {
        withAnimation {
            do {
                try repository.moveToBookmark(inbox)
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func moveToArchive(_ inbox: Inbox) {
        withAnimation {
            do {
                try repository.moveToArchive(inbox)
            } catch {
                print("Failed to move to Archive: \(error)")
            }
        }
    }

    private func deleteInbox(_ inbox: Inbox) {
        withAnimation {
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
