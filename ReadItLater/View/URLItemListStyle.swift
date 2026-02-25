//
//  URLItemListStyle.swift
//  ReadItLater
//
//  Created by Codex on 2026/02/25.
//

import SwiftUI

private struct URLItemListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(
                EdgeInsets(
                    top: AppSpacing.small,
                    leading: AppSpacing.large,
                    bottom: AppSpacing.small,
                    trailing: AppSpacing.large
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private struct URLItemListScreenStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appBackgroundBase)
    }
}

extension View {
    func urlItemListRowStyle() -> some View {
        modifier(URLItemListRowStyle())
    }

    func urlItemListScreenStyle() -> some View {
        modifier(URLItemListScreenStyle())
    }
}
