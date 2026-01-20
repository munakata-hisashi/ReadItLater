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
            if let url = bookmark.maybeURL {
                WebView(url: url)
            } else {
                VStack {
                    Text(bookmark.safeTitle)
                    Text("No URL")
                }
            }
        }
        .navigationTitle(bookmark.safeTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let container = ModelContainerFactory.createPreviewContainer()
    let example = Bookmark(
        url: "https://example.com",
        title: "Example",
        addedInboxAt: Date.now
    )
    BookmarkView(bookmark: example)
        .modelContainer(container)
}


