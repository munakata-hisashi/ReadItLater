//
//  MainTab.swift
//  ReadItLater
//
//  メイン画面のタブ識別子
//

import Foundation

/// メイン画面で表示するタブ
///
/// DeepLinkや画面遷移時の選択状態を表す。
enum MainTab: Hashable {
    case inbox
    case bookmarks
    case archive
}
