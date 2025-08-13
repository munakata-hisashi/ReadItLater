//
//  BookmarkView.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/13.
//

import SwiftUI
import SwiftData

struct BookmarkView: View {
    @Bindable var bookmark: Bookmark

    var body: some View {
        VStack {
            Text(bookmark.safeTitle)
           
            Text(bookmark.maybeURL?.absoluteString ?? "No URL")
        }
        .navigationTitle(bookmark.safeTitle)
        .navigationBarTitleDisplayMode(.inline)

    }
}

#Preview {
  
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bookmark.self, configurations: config)
    let example = Bookmark(url: "https://example.com")
    BookmarkView(bookmark: example)
            .modelContainer(container)
}


