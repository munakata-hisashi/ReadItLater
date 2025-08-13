//
//  BookmarkView.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/13.
//

import SwiftUI
import SwiftData

struct BookmarkView: View {
    @Bindable var item: Item

    var body: some View {
        VStack {
            Text(item.safeTitle)
           
            Text(item.maybeURL?.absoluteString ?? "No URL")
        }
        .navigationTitle(item.safeTitle)
        .navigationBarTitleDisplayMode(.inline)

    }
}

#Preview {
  
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Item.self, configurations: config)
        let example = Item(url: "https://example.com", title: "Title")
        BookmarkView(item: example)
            .modelContainer(container)
}


