//
//  FloatingTabBar.swift
//  ReadItLater
//

import SwiftUI

private struct TabItem {
    let tab: MainTab
    let icon: String
    let label: String
}

private let tabItems: [TabItem] = [
    TabItem(tab: .inbox, icon: "tray", label: "Inbox"),
    TabItem(tab: .bookmarks, icon: "bookmark", label: "Bookmarks"),
    TabItem(tab: .archive, icon: "archivebox", label: "Archive"),
]

/// フローティングカプセル型タブバー
///
/// matchedGeometryEffect でインジケーターをアニメーション。
/// VoiceOver のアクセシビリティ対応済み。
struct FloatingTabBar: View {
    @Binding var selectedTab: MainTab
    @Namespace private var indicatorNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabItems, id: \.tab) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, AppSpacing.xSmall)
        .padding(.vertical, AppSpacing.xSmall)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        .padding(.horizontal, AppSpacing.large)
    }

    @ViewBuilder
    private func tabButton(_ item: TabItem) -> some View {
        let isSelected = selectedTab == item.tab

        Button {
            withAnimation(AppAnimation.standard) {
                selectedTab = item.tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)
                Text(item.label)
                    .font(AppFont.footnote())
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.xSmall)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AppColors.brandPrimary)
                        .matchedGeometryEffect(id: "indicator", in: indicatorNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTab = .inbox

    VStack {
        Spacer()
        FloatingTabBar(selectedTab: $selectedTab)
        Spacer()
            .frame(height: 20)
    }
    .background(AppColors.backgroundPrimary)
}
