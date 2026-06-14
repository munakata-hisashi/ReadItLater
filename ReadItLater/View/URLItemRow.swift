//
//  URLItemRow.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI

/// リストアイテムの共通表示コンポーネント
///
/// URLItemプロトコルに準拠したモデルの共通表示ビュー
struct URLItemRow: View {
    let item: any URLItemDisplayable
    @Environment(\.colorScheme) private var colorScheme

    /// Dynamic Type対応の2行分の最小高さ
    @ScaledMetric(relativeTo: .headline) private var titleMinHeight: CGFloat = 44
    @ScaledMetric(relativeTo: .headline) private var stateIconSize: CGFloat = 28
    @ScaledMetric(relativeTo: .caption) private var stateBadgeVerticalPadding: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                Circle()
                    .fill(itemStateColor.opacity(colorScheme == .dark ? 0.3 : 0.16))
                    .overlay(
                        Image(systemName: itemStateIcon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(itemStateColor)
                    )
                    .frame(width: stateIconSize, height: stateIconSize)

                Text(item.safeTitle)
                    .font(AppFont.listTitle())
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .frame(minHeight: titleMinHeight, alignment: .topLeading)

                Spacer(minLength: 0)
            }

            if let urlString = item.url, !urlString.isEmpty {
                Text(urlString)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
            }

            HStack(spacing: AppSpacing.small) {
                Text(itemStateTitle)
                    .font(AppFont.caption())
                    .foregroundStyle(itemStateColor)
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, stateBadgeVerticalPadding)
                    .background(
                        Capsule().fill(itemStateColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    )

                Spacer(minLength: 0)

                Text(item.addedInboxAt, format: .dateTime.year().month(.abbreviated).day())
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                        .strokeBorder(
                            colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .dark
                        ? Color.appBrandPrimary.opacity(0.14)
                        : Color.black.opacity(0.08),
                    radius: colorScheme == .dark ? 12 : 8,
                    x: 0,
                    y: colorScheme == .dark ? 0 : 3
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(itemStateTitle), \(item.safeTitle)")
        .accessibilityValue(item.url ?? "No URL")
        .accessibilityHint("Added on \(item.addedInboxAt.formatted(date: .abbreviated, time: .omitted))")
    }

    private var itemStateTitle: String {
        switch item.itemStatus {
        case .inbox:
            return "Inbox"
        case .bookmark:
            return "Bookmark"
        case .archive, nil:
            return "Archive"
        }
    }

    private var itemStateIcon: String {
        switch item.itemStatus {
        case .inbox:
            return "tray.fill"
        case .bookmark:
            return "bookmark.fill"
        case .archive, nil:
            return "archivebox.fill"
        }
    }

    private var itemStateColor: Color {
        switch item.itemStatus {
        case .inbox:
            return Color.appBrandAccent
        case .bookmark:
            return Color.appBrandSecondary
        case .archive, nil:
            return Color.appBrandPrimary
        }
    }
}

#Preview {
    let container = ModelContainerFactory.createPreviewContainer()
    let exampleInbox = Inbox(url: "https://example.com", title: "Example Inbox")

    return List {
        URLItemRow(item: exampleInbox)
    }
    .modelContainer(container)
}
