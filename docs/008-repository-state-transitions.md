# 008: Repository層完成 - 状態移動ロジック

## 背景と目的

007でInboxへの追加機能を実装し、実データを扱える状態になりました。次のステップとして、**Inbox/Bookmark/Archive間の状態移動ロジック**を実装します。

### このステップの目的

- Repository層に状態移動メソッドを追加
- 各モデル間の変換ロジックを実装
- ユニットテストで状態移動が正しく動作することを検証

### 段階的実装の位置づけ

- **006**: スキーママイグレーション（基盤のみ）✅
- **007**: Share Extension対応（Inbox追加機能）✅
- **008** (本ドキュメント): Repository層完成（状態移動ロジック）
- **009**: UI実装（タブとリスト表示）

**008のゴール**: プログラムから状態移動ができ、ユニットテストで動作が保証されている状態にすること

---

## 前提条件

- 006が完了していること
  - AppV3Schemaが定義されている
  - 軽量マイグレーションが実装されている

- 007が完了していること
  - InboxConfigurationが定義されている
  - URLItemRepositoryProtocolが定義されている（Inbox操作のみ）
  - URLItemRepositoryが実装されている（Inbox追加のみ）

---

## 実装内容

### 1. URLItemRepositoryProtocol - 状態移動メソッド追加

007で定義したプロトコルに状態移動メソッドを追加します。

```swift
//
//  URLItemRepositoryProtocol.swift
//  ReadItLater
//

import Foundation

protocol URLItemRepositoryProtocol {
    // MARK: - Inbox操作

    func addToInbox(url: String, title: String) throws
    func canAddToInbox() -> Bool
    func inboxCount() -> Int
    func remainingInboxCapacity() -> Int

    // MARK: - 状態移動

    func moveToBookmark(_ inbox: Inbox) throws
    func moveToArchive(_ inbox: Inbox) throws
    func moveToArchive(_ bookmark: Bookmark) throws
    func moveToBookmark(_ archive: Archive) throws

    // MARK: - 削除

    func delete(_ inbox: Inbox)
    func delete(_ bookmark: Bookmark)
    func delete(_ archive: Archive)
}
```

**技術ポイント**:
- 各モデルを明示的に型指定（型安全性）
- 状態移動のメソッドを型安全に定義
- 削除メソッドも追加

### 2. URLItemRepository - 状態移動ロジック実装

既存のURLItemRepository.swiftに状態移動メソッドを実装します。

```swift
//
//  URLItemRepository.swift
//  ReadItLater
//

import Foundation
import SwiftData

final class URLItemRepository: URLItemRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Inbox操作
    // （007で実装済みのため省略）

    // MARK: - 状態移動

    func moveToBookmark(_ inbox: Inbox) throws {
        let bookmark = Bookmark(
            url: inbox.url ?? "",
            title: inbox.title ?? "",
            addedInboxAt: inbox.addedInboxAt  // 元の追加日時を引き継ぐ
        )

        modelContext.insert(bookmark)
        modelContext.delete(inbox)
        try modelContext.save()
    }

    func moveToArchive(_ inbox: Inbox) throws {
        let archive = Archive(
            url: inbox.url ?? "",
            title: inbox.title ?? "",
            addedInboxAt: inbox.addedInboxAt  // 元の追加日時を引き継ぐ
        )

        modelContext.insert(archive)
        modelContext.delete(inbox)
        try modelContext.save()
    }

    func moveToArchive(_ bookmark: Bookmark) throws {
        let archive = Archive(
            url: bookmark.url ?? "",
            title: bookmark.title ?? "",
            addedInboxAt: bookmark.addedInboxAt  // 元の追加日時を引き継ぐ
        )

        modelContext.insert(archive)
        modelContext.delete(bookmark)
        try modelContext.save()
    }

    func moveToBookmark(_ archive: Archive) throws {
        let bookmark = Bookmark(
            url: archive.url ?? "",
            title: archive.title ?? "",
            addedInboxAt: archive.addedInboxAt  // 元の追加日時を引き継ぐ
        )

        modelContext.insert(bookmark)
        modelContext.delete(archive)
        try modelContext.save()
    }

    // MARK: - 削除

    func delete(_ inbox: Inbox) {
        modelContext.delete(inbox)
    }

    func delete(_ bookmark: Bookmark) {
        modelContext.delete(bookmark)
    }

    func delete(_ archive: Archive) {
        modelContext.delete(archive)
    }
}
```

**技術ポイント**:
- 状態移動は「新規作成 + 削除」のシンプルな実装
- `addedInboxAt`を引き継ぐことで元の追加日時を保持
- 型安全性により、誤った移動を防止

### 3. ユニットテスト

状態移動ロジックをテストします。

```swift
//
//  URLItemRepositoryTests.swift
//  ReadItLaterTests
//

import Testing
import Foundation
import SwiftData
@testable import ReadItLater

struct URLItemRepositoryTests {
    var modelContext: ModelContext!
    var repository: URLItemRepository!

    init() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Inbox.self, Bookmark.self, Archive.self,
            migrationPlan: AppMigrationPlan.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        repository = URLItemRepository(modelContext: modelContext)
    }

    // MARK: - Inbox操作テスト（007で実装済み）

    @Test("Inboxに追加できる")
    func addToInbox() throws {
        // When: Inboxに追加
        try repository.addToInbox(url: "https://example.com", title: "Test")

        // Then: Inboxに存在する
        let descriptor = FetchDescriptor<Inbox>()
        let inboxItems = try modelContext.fetch(descriptor)
        #expect(inboxItems.count == 1)
        #expect(inboxItems.first?.url == "https://example.com")
    }

    @Test("Inbox上限チェック")
    func inboxCapacityCheck() throws {
        // Given: 上限未満
        for i in 0..<(InboxConfiguration.maxItems - 1) {
            try repository.addToInbox(
                url: "https://example.com/\(i)",
                title: "Item \(i)"
            )
        }

        // Then: 追加可能
        #expect(repository.canAddToInbox())
        #expect(repository.remainingInboxCapacity() == 1)
    }

    @Test("Inbox上限到達時はエラー")
    func inboxFullError() throws {
        // Given: 上限到達
        for i in 0..<InboxConfiguration.maxItems {
            try repository.addToInbox(
                url: "https://example.com/\(i)",
                title: "Item \(i)"
            )
        }

        // Then: 追加不可
        #expect(!repository.canAddToInbox())
        #expect(throws: RepositoryError.inboxFull) {
            try repository.addToInbox(url: "https://example.com/new", title: "New")
        }
    }

    // MARK: - 状態移動テスト（008で新規追加）

    @Test("InboxからBookmarkへ移動")
    func moveInboxToBookmark() throws {
        // Given: Inboxアイテム
        try repository.addToInbox(url: "https://example.com", title: "Test")
        let inboxDescriptor = FetchDescriptor<Inbox>()
        let inbox = try modelContext.fetch(inboxDescriptor).first!
        let originalAddedAt = inbox.addedInboxAt

        // When: Bookmarkへ移動
        try repository.moveToBookmark(inbox)

        // Then: Bookmarkに存在し、Inboxから削除
        let bookmarkDescriptor = FetchDescriptor<Bookmark>()
        let bookmarks = try modelContext.fetch(bookmarkDescriptor)
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.url == "https://example.com")
        #expect(bookmarks.first?.addedInboxAt == originalAddedAt)  // 日時が引き継がれる

        let remainingInbox = try modelContext.fetch(inboxDescriptor)
        #expect(remainingInbox.isEmpty)
    }

    @Test("InboxからArchiveへ移動")
    func moveInboxToArchive() throws {
        // Given: Inboxアイテム
        try repository.addToInbox(url: "https://example.com", title: "Test")
        let inbox = try modelContext.fetch(FetchDescriptor<Inbox>()).first!
        let originalAddedAt = inbox.addedInboxAt

        // When: Archiveへ移動
        try repository.moveToArchive(inbox)

        // Then: Archiveに存在
        let archives = try modelContext.fetch(FetchDescriptor<Archive>())
        #expect(archives.count == 1)
        #expect(archives.first?.url == "https://example.com")
        #expect(archives.first?.addedInboxAt == originalAddedAt)
    }

    @Test("BookmarkからArchiveへ移動")
    func moveBookmarkToArchive() throws {
        // Given: Inboxからbookmarkを作成
        try repository.addToInbox(url: "https://example.com", title: "Test")
        let inbox = try modelContext.fetch(FetchDescriptor<Inbox>()).first!
        try repository.moveToBookmark(inbox)
        let bookmark = try modelContext.fetch(FetchDescriptor<Bookmark>()).first!
        let originalAddedAt = bookmark.addedInboxAt

        // When: Archiveへ移動
        try repository.moveToArchive(bookmark)

        // Then: Archiveに存在
        let archives = try modelContext.fetch(FetchDescriptor<Archive>())
        #expect(archives.count == 1)
        #expect(archives.first?.url == "https://example.com")
        #expect(archives.first?.addedInboxAt == originalAddedAt)
    }

    @Test("ArchiveからBookmarkへ移動")
    func moveArchiveToBookmark() throws {
        // Given: Archiveアイテムを作成
        try repository.addToInbox(url: "https://example.com", title: "Test")
        let inbox = try modelContext.fetch(FetchDescriptor<Inbox>()).first!
        try repository.moveToArchive(inbox)
        let archive = try modelContext.fetch(FetchDescriptor<Archive>()).first!
        let originalAddedAt = archive.addedInboxAt

        // When: Bookmarkへ移動
        try repository.moveToBookmark(archive)

        // Then: Bookmarkに存在
        let bookmarks = try modelContext.fetch(FetchDescriptor<Bookmark>())
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.url == "https://example.com")
        #expect(bookmarks.first?.addedInboxAt == originalAddedAt)
    }

    @Test("削除操作")
    func deleteItems() throws {
        // Given: 各タイプのアイテム
        try repository.addToInbox(url: "https://example.com/1", title: "Test1")
        try repository.addToInbox(url: "https://example.com/2", title: "Test2")
        try repository.addToInbox(url: "https://example.com/3", title: "Test3")

        let inbox1 = try modelContext.fetch(FetchDescriptor<Inbox>()).first!
        try repository.moveToBookmark(inbox1)
        let bookmark = try modelContext.fetch(FetchDescriptor<Bookmark>()).first!

        let inbox2 = try modelContext.fetch(FetchDescriptor<Inbox>()).first!
        try repository.moveToArchive(inbox2)
        let archive = try modelContext.fetch(FetchDescriptor<Archive>()).first!

        let inbox3 = try modelContext.fetch(FetchDescriptor<Inbox>()).first!

        // When: 削除
        repository.delete(inbox3)
        repository.delete(bookmark)
        repository.delete(archive)

        // Then: 全て削除される
        #expect(try modelContext.fetch(FetchDescriptor<Inbox>()).isEmpty)
        #expect(try modelContext.fetch(FetchDescriptor<Bookmark>()).isEmpty)
        #expect(try modelContext.fetch(FetchDescriptor<Archive>()).isEmpty)
    }

    @Test("addedInboxAtが正しく引き継がれる")
    func preserveAddedInboxAt() throws {
        // Given: 特定の日時でInboxに追加
        let specificDate = Date(timeIntervalSince1970: 1234567890)
        let inbox = Inbox(url: "https://example.com", title: "Test", addedInboxAt: specificDate)
        modelContext.insert(inbox)
        try modelContext.save()

        // When: Bookmark → Archive → Bookmarkと移動
        try repository.moveToBookmark(inbox)
        let bookmark = try modelContext.fetch(FetchDescriptor<Bookmark>()).first!

        try repository.moveToArchive(bookmark)
        let archive = try modelContext.fetch(FetchDescriptor<Archive>()).first!

        try repository.moveToBookmark(archive)
        let finalBookmark = try modelContext.fetch(FetchDescriptor<Bookmark>()).first!

        // Then: 全ての移動でaddedInboxAtが保持される
        #expect(finalBookmark.addedInboxAt == specificDate)
    }
}
```

**技術ポイント**:
- Swift Testing APIを使用
- 別モデル方式の状態移動をテスト
- データが正しく移行されることを検証
- `addedInboxAt`が正しく引き継がれることを検証
- 型安全性が保証されることを確認

---

## 実装手順

### 1. URLItemRepositoryProtocol.swiftを更新

**ファイルパス**: `ReadItLater/Domain/URLItemRepositoryProtocol.swift`

状態移動メソッドと削除メソッドを追加します（上記のコード参照）。

### 2. URLItemRepository.swiftを更新

**ファイルパス**: `ReadItLater/Infrastructure/URLItemRepository.swift`

状態移動ロジックを実装します（上記のコード参照）。

### 3. URLItemRepositoryTests.swiftを作成

**ファイルパス**: `ReadItLaterTests/Infrastructure/URLItemRepositoryTests.swift`

状態移動のユニットテストを実装します（上記のコード参照）。

---

## 修正対象ファイル一覧

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `Domain/URLItemRepositoryProtocol.swift` | 状態移動メソッドと削除メソッドを追加 |
| `Infrastructure/URLItemRepository.swift` | 状態移動ロジックと削除ロジックを実装 |

### 新規ファイル

| ファイル | 目的 |
|---------|------|
| `ReadItLaterTests/Infrastructure/URLItemRepositoryTests.swift` | 状態移動と上限チェックのテスト |

---

## 検証方法

### ビルド確認
```bash
mise run build
```

### ユニットテスト実行
```bash
mise run unit
```

または

```bash
xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' \
  test -only-testing:ReadItLaterTests
```

### テスト項目

- ✅ Inboxに追加できる
- ✅ Inbox上限チェック
- ✅ Inbox上限到達時はエラー
- ✅ InboxからBookmarkへ移動
- ✅ InboxからArchiveへ移動
- ✅ BookmarkからArchiveへ移動
- ✅ ArchiveからBookmarkへ移動
- ✅ 削除操作
- ✅ addedInboxAtが正しく引き継がれる

---

## トラブルシューティング

### テストが失敗する場合

**原因1**: ModelContainerの初期化に失敗している

**対策**:
```swift
let container = try ModelContainer(
    for: Inbox.self, Bookmark.self, Archive.self,  // 全てのモデルを指定
    migrationPlan: AppMigrationPlan.self,
    configurations: config
)
```

**原因2**: `addedInboxAt`がnilになる

**対策**: Bookmarkのinitで`addedInboxAt`を必須引数にしているか確認

### 状態移動後にデータが見つからない

**原因**: `modelContext.save()`が実行されていない

**対策**: 状態移動メソッドの最後で`try modelContext.save()`を実行

---

## 次のステップ

008の実装完了後、以下の順序で機能を追加していきます：

1. **009: UI実装** - 3タブUIとスワイプアクションを実装し、エンドユーザーが操作可能に

---

## 技術的補足

### 別モデル方式の状態移動

**実装方針**:
1. 新しいモデルのインスタンスを作成
2. 元のモデルから必要なデータをコピー
3. 元のモデルを削除
4. `modelContext.save()`で確定

**メリット**:
- 型安全性が保証される
- 各モデルが独立して進化できる
- コンパイル時にエラーを検出

**デメリット**:
- コピー処理が必要
- CloudKit同期で削除＋作成の2操作になる

### CloudKit同期

**同期の仕組み**:
- 状態移動時は「削除 + 作成」の2操作として同期される
- オフライン時に競合が発生する可能性があるが、使用パターン上は稀
- 影響は限定的（1件のみ、URLは再取得可能）

### パフォーマンス

**クエリ効率**:
- 各モデルは独立したテーブルとして管理
- `@Query`は型ごとに最適化されたインデックスを利用
- `fetchCount`は全件取得せずカウントのみ取得

---

## 実装予定日

2026-01-18
