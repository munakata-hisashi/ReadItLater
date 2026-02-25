//
//  MainTabView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI

/// アプリのメインタブビュー
///
/// Inbox、Bookmarks、Archiveの3つのタブを提供。
/// ネイティブ TabView でタブ状態（NavigationStack, searchText 等）を保持しつつ、
/// フローティングカプセル型タブバーを採用。
struct MainTabView: View {
    @Binding var selectedTab: MainTab
    @State private var hideTabBar = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    InboxListView()
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(MainTab.inbox)

                NavigationStack {
                    BookmarkListView()
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(MainTab.bookmarks)

                NavigationStack {
                    ArchiveListView()
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(MainTab.archive)
            }
            .environment(\.hideFloatingTabBar, $hideTabBar)

            if !hideTabBar {
                FloatingTabBar(selectedTab: $selectedTab)
                    .padding(.bottom, AppSpacing.xSmall)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    MainTabView(selectedTab: .constant(.inbox))
        .modelContainer(ModelContainerFactory.createPreviewContainer())
}
