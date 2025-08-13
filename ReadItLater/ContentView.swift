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
                    Button(action: addBookmark) {
                        Label("Add Bookmark", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an Bookmark")
        }
    }

    private func addBookmark() {
        withAnimation {
            let newBookmark = Bookmark(url: "https://example.com")
            modelContext.insert(newBookmark)
        }
    }

    private func deleteBookmarks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(bookmarks[index])
            }
        }
    }
}

#Preview {
    let schema = Schema([
        Item.self,
        Bookmark.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    let modelContainer = try! ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: modelConfiguration)
    ContentView()
        .modelContainer(modelContainer)
}
