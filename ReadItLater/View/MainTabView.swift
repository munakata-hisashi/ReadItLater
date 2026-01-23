//
//  MainTabView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI

/// アプリのメインタブビュー
///
/// Inbox、Bookmarks、Archiveの3つのタブを提供
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                InboxListView()
            }
            .tabItem {
                Label("Inbox", systemImage: "tray")
            }

            NavigationStack {
                BookmarkListView()
            }
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }

            NavigationStack {
                ArchiveListView()
            }
            .tabItem {
                Label("Archive", systemImage: "archivebox")
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
