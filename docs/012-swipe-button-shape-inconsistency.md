# Issue: スワイプアクションボタンの形状が統一されない問題

## 問題の概要

スワイプアクションのボタン形状（アイコン背景）が画面によって統一されていない。

### 観察された現象
- **Bookmark画面**: すべてのボタンが円形
- **Inbox/Archive画面**: Deleteボタンのみ円形、他のボタン（Inbox, Bookmark, Archive）は角丸長方形

### 期待される動作
すべての画面のスワイプアクションボタンが統一された形状（円形アイコン＋下にラベル）で表示される。

## 調査内容

### コード構造の確認

3つの画面（InboxListView, BookmarkListView, ArchiveListView）のswipeActions実装は同じ構造：

```swift
.swipeActions(edge: .leading, allowsFullSwipe: true) {
    // 2つのアクションボタン
}
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    DeleteSwipeButton { }  // role: .destructive あり
}
```

**ボタン定義** (`ItemSwipeActions.swift`):
- `InboxSwipeButton`: `role`指定なし
- `BookmarkSwipeButton`: `role`指定なし
- `ArchiveSwipeButton`: `role`指定なし
- `DeleteSwipeButton`: `role: .destructive` あり

### 原因の推測

1. **Button roleの影響**: `role: .destructive`を持つボタンとそうでないボタンで、SwiftUIが異なる表示形状を適用している可能性
2. **SwiftUIの内部実装**: swipeActionsのボタン形状はシステムが自動制御しており、開発者が直接カスタマイズできない
3. **iOS/デバイス依存**: iOSバージョンやデバイスによる表示の違い

## 試したアプローチ

### 試行1: `.buttonStyle(.borderless)`の適用

**コード**:
```swift
Button(action: action) {
    Label("Inbox", systemImage: "tray")
}
.tint(.orange)
.buttonStyle(.borderless)
```

**結果**: ❌ スワイプ操作が完全に効かなくなった

**コミット履歴**:
- `30d0063`: buttonStyleを適用
- `6d03237`: revert（スワイプ操作復旧のため削除）

### 検討したが未実施のアプローチ

1. **カスタムButtonStyleの作成**
   - SwiftUIのButtonStyleプロトコルを使用してカスタムスタイルを定義
   - swipeActions内で正しく機能するか不明

2. **Labelのカスタムレイアウト**
   - VStackでアイコンとテキストを縦配置
   - swipeActionsの自動レイアウトと競合する可能性

3. **すべてのボタンに`role`を設定**
   - ただし、SwiftUIのButton roleは`.destructive`と`.cancel`のみ
   - 他のroleは存在しない

## 技術的制約

### SwiftUIの制限
- `swipeActions`のボタン形状はシステムレベルで制御されている
- 公式APIでボタンの背景形状を直接指定する方法が存在しない
- `.buttonStyle`の適用はswipeActions内で予期しない動作を引き起こす

### 代替案の難しさ
- カスタムスワイプジェスチャの実装は複雑で、システム標準のUXと乖離する
- `.swipeActions`を使わない場合、アクセシビリティや標準動作が失われる

## 現状の結論

**SwiftUIの標準`swipeActions`を使用している限り、ボタン形状の完全な統一は困難**

### 考えられる対応

#### Option 1: 現状維持
- SwiftUIの標準動作として受け入れる
- ユーザー体験への影響は限定的（機能は正常に動作）

#### Option 2: 将来のSwiftUIアップデートを待つ
- Appleが将来のiOS/SwiftUIバージョンでカスタマイズAPIを提供する可能性
- WWDC等で新しいAPIが発表されるか注視

#### Option 3: カスタム実装（非推奨）
- `swipeActions`を使わず、完全にカスタムのスワイプジェスチャを実装
- 開発コストが高く、アクセシビリティの問題が発生する可能性

## 関連ファイル

- `ReadItLater/View/ItemSwipeActions.swift` - ボタン定義
- `ReadItLater/View/InboxListView.swift` - Inbox画面のswipeActions
- `ReadItLater/View/BookmarkListView.swift` - Bookmark画面のswipeActions
- `ReadItLater/View/ArchiveListView.swift` - Archive画面のswipeActions

## 参考情報

### SwiftUI公式ドキュメント
- [swipeActions](https://developer.apple.com/documentation/swiftui/view/swipeactions(edge:allowsfullswipe:content:))
- [ButtonStyle](https://developer.apple.com/documentation/swiftui/buttonstyle)
- [Button.Role](https://developer.apple.com/documentation/swiftui/buttonrole)

## ステータス

**Open** - 技術的制約により現時点で解決困難

## 更新履歴

- 2026-01-31: Issue作成、`.buttonStyle(.borderless)`アプローチを試行したが失敗
