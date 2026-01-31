# Bookmark/ArchiveからInboxへ戻す機能の実装

## 背景と目的

### 現状の問題
- 008で状態移動ロジック（Inbox → Bookmark/Archive）を実装したが、Inboxへ戻す機能は未実装
- ユーザーが誤ってBookmark/Archiveに移動した場合に元に戻せない
- 一度Bookmark/Archiveに移動すると、削除して再度追加するしかない

### 目的
本機能の実装により、Bookmark ↔ Inbox ↔ Archiveの双方向移動を完成させ、ユーザーが柔軟にアイテムを整理できるようにする。

## 実装内容

### 1. Domain層 - プロトコル拡張
- `BookmarkRepositoryProtocol`: `moveToInbox(_ bookmark:, using inboxRepository:)` メソッド追加
- `ArchiveRepositoryProtocol`: `moveToInbox(_ archive:, using inboxRepository:)` メソッド追加

### 2. Infrastructure層 - 実装
- `BookmarkRepository`: `moveToInbox`の実装
  1. Inbox容量チェック（`inboxRepository.canAdd()`）
  2. Inbox作成
  3. Bookmark削除
  4. 保存
- `ArchiveRepository`: `moveToInbox`の実装（同様の流れ）

### 3. View層 - UI追加
- `ItemSwipeActions.swift`: `InboxSwipeButton`コンポーネント追加
  - アイコン: `tray`
  - カラー: オレンジ
- `BookmarkListView`: Leading swipeにInboxSwipeButton追加
- `ArchiveListView`: Leading swipeにInboxSwipeButton追加

### 4. テスト追加
- `BookmarkRepositoryTests`: Bookmark→Inbox移動テスト、容量制限テスト
- `ArchiveRepositoryTests`: Archive→Inbox移動テスト、容量制限テスト

## 技術ポイント

### InboxRepositoryを引数に渡す設計理由

```swift
func moveToInbox(_ bookmark: Bookmark, using inboxRepository: InboxRepositoryProtocol) throws
```

この設計には以下の理由がある:

1. **Inbox容量チェックの必要性**
   - `InboxConfiguration.maxItems`による上限管理
   - `canAdd()`メソッドで事前に移動可能か判定

2. **同じModelContextの共有保証**
   - 両リポジトリが同じModelContextを使うことで、トランザクション整合性を確保
   - 削除と追加が同一コンテキスト内で実行される

3. **テスタビリティ**
   - モックリポジトリを注入してテスト可能
   - 依存関係が明示的

### 状態遷移時のデータ保持

移動時に以下のデータを維持:
- `url`: URL本体
- `title`: タイトル
- `addedInboxAt`: **最初にInboxに追加した日時**（重要）

`addedInboxAt`を保持することで、ユーザーがアイテムを最初に保存した時期を追跡できる。

### スワイプアクションの配置

| 画面 | Leading（左スワイプ） | Trailing（右スワイプ） |
|------|----------------------|------------------------|
| Inbox | Bookmark(青), Archive(緑) | Delete(赤) |
| Bookmark | **Inbox(橙)**, Archive(緑) | Delete(赤) |
| Archive | **Inbox(橙)**, Bookmark(青) | Delete(赤) |

すべての画面でInboxへのアクセスが可能になり、整理の自由度が向上。

## エラーハンドリング

### Inbox満杯時
- `InboxRepository.canAdd()`が`false`を返す
- `InboxError.capacityExceeded`をスロー
- View層で`print()`によるエラー出力（将来的にはUIでアラート表示を検討）

## 検証方法

### 1. ビルド確認
```bash
mise run b
```

### 2. ユニットテスト実行
```bash
mise run u
```

### 3. シミュレータでの手動検証
1. Bookmarkアイテムを左スワイプ → Inboxボタン（オレンジ）タップ
   - Inboxに移動することを確認
   - Bookmarkから削除されることを確認
2. Archiveアイテムを左スワイプ → Inboxボタン（オレンジ）タップ
   - Inboxに移動することを確認
   - Archiveから削除されることを確認
3. Inboxが満杯の状態で移動を試行
   - エラーがコンソールに出力されることを確認
   - アイテムが移動しないことを確認

## 実装順序

1. ✅ ドキュメント作成（本ドキュメント）
2. Domain層のプロトコル拡張
3. Infrastructure層の実装
4. テストコード作成
5. View層のUI追加
6. 動作確認

## 関連Issue/PR

- 関連: #008（状態移動ロジックの基礎実装）
- 本実装でBookmark/Archiveからの逆方向移動を完成

## 今後の改善案

- エラー時のUIフィードバック強化（アラート表示）
- Undo/Redo機能の追加
- 一括移動機能の検討
