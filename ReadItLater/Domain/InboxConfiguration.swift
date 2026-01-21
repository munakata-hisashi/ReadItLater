//
//  InboxConfiguration.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/22.
//

import Foundation

/// Inboxの設定値
enum InboxConfiguration {
    /// inbox内の最大保存数
    /// 開発時: 検証用に5件。将来的には50件に変更予定
    static let maxItems: Int = 5

    /// 警告を表示する閾値（最大数の80%）
    static var warningThreshold: Int {
        Int(Double(maxItems) * 0.8)
    }
}
