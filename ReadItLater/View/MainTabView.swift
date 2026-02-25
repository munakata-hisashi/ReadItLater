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
/// フローティングカプセル型タブバーを採用。
struct MainTabView: View {
    @Binding var selectedTab: MainTab
    @State private var hideTabBar = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .inbox:
                    NavigationStack {
                        InboxListView()
                    }
                case .bookmarks:
                    NavigationStack {
                        BookmarkListView()
                    }
                case .archive:
                    NavigationStack {
                        ArchiveListView()
                    }
                }
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
