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
    @Binding var selectedTab: MainTab

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                InboxListView()
            }
            .tabItem {
                Label("Inbox", systemImage: "tray")
            }
            .tag(MainTab.inbox)

            NavigationStack {
                BookmarkListView()
            }
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }
            .tag(MainTab.bookmarks)

            NavigationStack {
                ArchiveListView()
            }
            .tabItem {
                Label("Archive", systemImage: "archivebox")
            }
            .tag(MainTab.archive)
        }
    }
}

#Preview {
    MainTabView(selectedTab: .constant(.inbox))
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
