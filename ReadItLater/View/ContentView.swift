//
//  ContentView.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]
    @State private var showingAddSheet = false

    /// Repository（computed propertyとして生成）
    private var repository: BookmarkRepositoryProtocol {
        BookmarkRepository(modelContext: modelContext)
    }

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(bookmarks) { bookmark in
                    NavigationLink(value: bookmark) {
                        VStack {
                            Text(bookmark.safeTitle)
                            Text(bookmark.id.uuidString)
                        }
                    }
                }
                .onDelete(perform: deleteBookmarks)
            }
            .navigationTitle("Bookmarks")
            .navigationDestination(for: Bookmark.self, destination: BookmarkView.init)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Bookmark", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an Bookmark")
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBookmarkSheet(
                onSave: { bookmarkData in
                    addBookmark(from: bookmarkData)
                    showingAddSheet = false
                },
                onCancel: {
                    showingAddSheet = false
                }
            )
        }
    }

    private func addBookmark(from bookmarkData: BookmarkData) {
        withAnimation {
            repository.add(bookmarkData)
        }
    }

    private func deleteBookmarks(offsets: IndexSet) {
        withAnimation {
            let bookmarksToDelete = offsets.map { bookmarks[$0] }
            repository.delete(bookmarksToDelete)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
