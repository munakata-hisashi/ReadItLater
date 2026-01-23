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
  - InboxRepositoryProtocolとInboxRepositoryが実装されている（Inbox追加のみ）
  - BookmarkRepositoryProtocolとBookmarkRepositoryが実装されている

---

## 実装内容

### 1. ArchiveRepositoryProtocol - 新規作成

Archive操作のためのプロトコルを定義します。

```swift
//
//  ArchiveRepositoryProtocol.swift
//  ReadItLater
//

import Foundation

/// Archive永続化操作のためのプロトコル
protocol ArchiveRepositoryProtocol {
    // MARK: - 状態移動

    /// ArchiveからBookmarkへ移動
    /// - Parameter archive: 移動元のArchive
    /// - Throws: SwiftDataのエラー
    func moveToBookmark(_ archive: Archive) throws

    // MARK: - 削除

    /// Archiveを削除
    /// - Parameter archive: 削除対象のArchive
    func delete(_ archive: Archive)
}
```

**技術ポイント**:
- Archiveモデル固有の操作を定義
- 007で作成したInboxRepository、BookmarkRepositoryと同じパターン

### 2. ArchiveRepository - 新規実装

Archive操作の実装を提供します。

```swift
//
//  ArchiveRepository.swift
//  ReadItLater
//

import Foundation
import SwiftData

/// SwiftDataを使用したArchiveRepository実装
final class ArchiveRepository: ArchiveRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 状態移動

    func moveToBookmark(_ archive: Archive) throws {
        let bookmark = Bookmark(
            url: archive.url ?? "",
            title: archive.title ?? "",
            addedInboxAt: archive.addedInboxAt,  // 元の追加日時を引き継ぐ
            bookmarkedAt: Date.now  // Bookmarkに移動した日時
        )

        modelContext.insert(bookmark)
        modelContext.delete(archive)
        try modelContext.save()
    }

    // MARK: - 削除

    func delete(_ archive: Archive) {
        modelContext.delete(archive)
    }
}
```

### 3. InboxRepositoryProtocol - 状態移動メソッド追加

既存のInboxRepositoryProtocolに状態移動メソッドを追加します。

```swift
protocol InboxRepositoryProtocol {
    // MARK: - 追加操作（007で実装済み）

    func add(url: String, title: String) throws
    func canAdd() -> Bool
    func count() -> Int
    func remainingCapacity() -> Int

    // MARK: - 状態移動（008で追加）

    /// InboxからBookmarkへ移動
    /// - Parameter inbox: 移動元のInbox
    /// - Throws: SwiftDataのエラー
    func moveToBookmark(_ inbox: Inbox) throws

    /// InboxからArchiveへ移動
    /// - Parameter inbox: 移動元のInbox
    /// - Throws: SwiftDataのエラー
    func moveToArchive(_ inbox: Inbox) throws

    // MARK: - 削除（008で追加）

    /// Inboxを削除
    /// - Parameter inbox: 削除対象のInbox
    func delete(_ inbox: Inbox)
}
```

### 4. InboxRepository - 状態移動ロジック実装

既存のInboxRepositoryに状態移動メソッドを実装します。

```swift
// MARK: - 状態移動

func moveToBookmark(_ inbox: Inbox) throws {
    let bookmark = Bookmark(
        url: inbox.url ?? "",
        title: inbox.title ?? "",
        addedInboxAt: inbox.addedInboxAt,  // 元の追加日時を引き継ぐ
        bookmarkedAt: Date.now  // Bookmarkに移動した日時
    )

    modelContext.insert(bookmark)
    modelContext.delete(inbox)
    try modelContext.save()
}

func moveToArchive(_ inbox: Inbox) throws {
    let archive = Archive(
        url: inbox.url ?? "",
        title: inbox.title ?? "",
        addedInboxAt: inbox.addedInboxAt,  // 元の追加日時を引き継ぐ
        archivedAt: Date.now  // Archiveに移動した日時
    )

    modelContext.insert(archive)
    modelContext.delete(inbox)
    try modelContext.save()
}

// MARK: - 削除

func delete(_ inbox: Inbox) {
    modelContext.delete(inbox)
}
```

### 5. BookmarkRepositoryProtocol - 状態移動メソッド追加

既存のBookmarkRepositoryProtocolに状態移動メソッドを追加します。

```swift
protocol BookmarkRepositoryProtocol {
    // MARK: - 追加操作（007で実装済み）

    func add(_ bookmarkData: BookmarkData)
    func delete(_ bookmark: Bookmark)
    func delete(_ bookmarks: [Bookmark])

    // MARK: - 状態移動（008で追加）

    /// BookmarkからArchiveへ移動
    /// - Parameter bookmark: 移動元のBookmark
    /// - Throws: SwiftDataのエラー
    func moveToArchive(_ bookmark: Bookmark) throws
}
```

### 6. BookmarkRepository - 状態移動ロジック実装

既存のBookmarkRepositoryに状態移動メソッドを実装します。

```swift
// MARK: - 状態移動

func moveToArchive(_ bookmark: Bookmark) throws {
    let archive = Archive(
        url: bookmark.url ?? "",
        title: bookmark.title ?? "",
        addedInboxAt: bookmark.addedInboxAt,  // 元の追加日時を引き継ぐ
        archivedAt: Date.now  // Archiveに移動した日時
    )

    modelContext.insert(archive)
    modelContext.delete(bookmark)
    try modelContext.save()
}
```

**技術ポイント**:
- 各Repositoryが自分のモデルの状態移動を担当
- 状態移動は「新規作成 + 削除」のシンプルな実装
- `addedInboxAt`を引き継ぐことで元の追加日時を保持
- `bookmarkedAt`/`archivedAt`は移動時の現在時刻を設定
- 型安全性により、誤った移動を防止

### 7. ユニットテスト

各Repository用のテストを作成します。

#### InboxRepositoryTests（既存テストに追加）

既存の`ReadItLaterTests/Infrastructure/InboxRepositoryTests.swift`に以下のテストを追加します。

```swift
// MARK: - 状態移動テスト（008で新規追加）

@Test("状態移動: InboxからBookmarkへ")
@MainActor
func 状態移動_InboxからBookmarkへ() throws {
    let container = try createInMemoryContainer()
    let context = container.mainContext
    let repository = InboxRepository(modelContext: context)

    // Given: Inboxアイテム
    try repository.add(url: "https://example.com", title: "Test")
    let inbox = try context.fetch(FetchDescriptor<Inbox>()).first!
    let originalAddedAt = inbox.addedInboxAt

    // When: Bookmarkへ移動
    try repository.moveToBookmark(inbox)

    // Then: Bookmarkに存在し、Inboxから削除
    let bookmarks = try context.fetch(FetchDescriptor<Bookmark>())
    #expect(bookmarks.count == 1)
    #expect(bookmarks.first?.url == "https://example.com")
    #expect(bookmarks.first?.addedInboxAt == originalAddedAt)

    let remainingInbox = try context.fetch(FetchDescriptor<Inbox>())
    #expect(remainingInbox.isEmpty)
}

@Test("状態移動: InboxからArchiveへ")
@MainActor
func 状態移動_InboxからArchiveへ() throws {
    let container = try createInMemoryContainer()
    let context = container.mainContext
    let repository = InboxRepository(modelContext: context)

    // Given: Inboxアイテム
    try repository.add(url: "https://example.com", title: "Test")
    let inbox = try context.fetch(FetchDescriptor<Inbox>()).first!
    let originalAddedAt = inbox.addedInboxAt

    // When: Archiveへ移動
    try repository.moveToArchive(inbox)

    // Then: Archiveに存在し、Inboxから削除
    let archives = try context.fetch(FetchDescriptor<Archive>())
    #expect(archives.count == 1)
    #expect(archives.first?.url == "https://example.com")
    #expect(archives.first?.addedInboxAt == originalAddedAt)

    let remainingInbox = try context.fetch(FetchDescriptor<Inbox>())
    #expect(remainingInbox.isEmpty)
}

@Test("削除: Inbox削除")
@MainActor
func 削除_Inbox削除() throws {
    let container = try createInMemoryContainer()
    let context = container.mainContext
    let repository = InboxRepository(modelContext: context)

    // Given: Inboxアイテム
    try repository.add(url: "https://example.com", title: "Test")
    let inbox = try context.fetch(FetchDescriptor<Inbox>()).first!

    // When: 削除
    repository.delete(inbox)
    try context.save()

    // Then: Inboxが空
    #expect(try context.fetch(FetchDescriptor<Inbox>()).isEmpty)
}
```

#### BookmarkRepositoryTests（既存テストに追加）

既存の`ReadItLaterTests/Infrastructure/BookmarkRepositoryTests.swift`に以下のテストを追加します。

```swift
// MARK: - 状態移動テスト（008で新規追加）

@Test("状態移動: BookmarkからArchiveへ")
@MainActor
func 状態移動_BookmarkからArchiveへ() throws {
    let container = try createInMemoryContainer()
    let context = container.mainContext
    let repository = BookmarkRepository(modelContext: context)

    // Given: Bookmarkを作成
    let bookmark = Bookmark(
        url: "https://example.com",
        title: "Test",
        addedInboxAt: Date(timeIntervalSince1970: 1234567890)
    )
    context.insert(bookmark)
    try context.save()

    let originalAddedAt = bookmark.addedInboxAt

    // When: Archiveへ移動
    try repository.moveToArchive(bookmark)

    // Then: Archiveに存在
    let archives = try context.fetch(FetchDescriptor<Archive>())
    #expect(archives.count == 1)
    #expect(archives.first?.url == "https://example.com")
    #expect(archives.first?.addedInboxAt == originalAddedAt)

    // Bookmarkから削除されている
    let remainingBookmarks = try context.fetch(FetchDescriptor<Bookmark>())
    #expect(remainingBookmarks.isEmpty)
}
```

#### ArchiveRepositoryTests（新規作成）

`ReadItLaterTests/Infrastructure/ArchiveRepositoryTests.swift`を新規作成します。

```swift
//
//  ArchiveRepositoryTests.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/22.
//

import Testing
import SwiftData
@testable import ReadItLater

@Suite("ArchiveRepository")
struct ArchiveRepositoryTests {

    // MARK: - Helper

    /// テスト用のin-memory ModelContainerを作成
    private func createInMemoryContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSharedContainer(inMemory: true)
    }

    // MARK: - 状態移動テスト

    @Test("状態移動: ArchiveからBookmarkへ")
    @MainActor
    func 状態移動_ArchiveからBookmarkへ() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = ArchiveRepository(modelContext: context)

        // Given: Archiveを作成
        let archive = Archive(
            url: "https://example.com",
            title: "Test",
            addedInboxAt: Date(timeIntervalSince1970: 1234567890)
        )
        context.insert(archive)
        try context.save()

        let originalAddedAt = archive.addedInboxAt

        // When: Bookmarkへ移動
        try repository.moveToBookmark(archive)

        // Then: Bookmarkに存在
        let bookmarks = try context.fetch(FetchDescriptor<Bookmark>())
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.url == "https://example.com")
        #expect(bookmarks.first?.addedInboxAt == originalAddedAt)

        // Archiveから削除されている
        let remainingArchives = try context.fetch(FetchDescriptor<Archive>())
        #expect(remainingArchives.isEmpty)
    }

    // MARK: - 削除テスト

    @Test("削除: Archive削除")
    @MainActor
    func 削除_Archive削除() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext
        let repository = ArchiveRepository(modelContext: context)

        // Given: Archiveを作成
        let archive = Archive(url: "https://example.com", title: "Test")
        context.insert(archive)
        try context.save()

        // When: 削除
        repository.delete(archive)
        try context.save()

        // Then: Archiveが空
        #expect(try context.fetch(FetchDescriptor<Archive>()).isEmpty)
    }
}
```

#### RepositoryIntegrationTests（新規作成）

複数Repositoryにまたがる統合テストを`ReadItLaterTests/Infrastructure/RepositoryIntegrationTests.swift`に作成します。

```swift
//
//  RepositoryIntegrationTests.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/22.
//

import Testing
import SwiftData
@testable import ReadItLater

@Suite("Repository統合テスト")
struct RepositoryIntegrationTests {

    // MARK: - Helper

    /// テスト用のin-memory ModelContainerを作成
    private func createInMemoryContainer() throws -> ModelContainer {
        try ModelContainerFactory.createSharedContainer(inMemory: true)
    }

    // MARK: - 状態移動連鎖テスト

    @Test("統合: addedInboxAtが全移動で保持される")
    @MainActor
    func 統合_addedInboxAtが全移動で保持される() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext

        let inboxRepository = InboxRepository(modelContext: context)
        let bookmarkRepository = BookmarkRepository(modelContext: context)
        let archiveRepository = ArchiveRepository(modelContext: context)

        // Given: 特定の日時でInboxに追加
        let specificDate = Date(timeIntervalSince1970: 1234567890)
        let inbox = Inbox(url: "https://example.com", title: "Test", addedInboxAt: specificDate)
        context.insert(inbox)
        try context.save()

        // Inbox → Bookmark
        try inboxRepository.moveToBookmark(inbox)
        let bookmark = try context.fetch(FetchDescriptor<Bookmark>()).first!
        #expect(bookmark.addedInboxAt == specificDate)

        // Bookmark → Archive
        try bookmarkRepository.moveToArchive(bookmark)
        let archive = try context.fetch(FetchDescriptor<Archive>()).first!
        #expect(archive.addedInboxAt == specificDate)

        // Archive → Bookmark
        try archiveRepository.moveToBookmark(archive)
        let finalBookmark = try context.fetch(FetchDescriptor<Bookmark>()).first!
        #expect(finalBookmark.addedInboxAt == specificDate)
    }

    @Test("統合: 複数アイテムの状態移動")
    @MainActor
    func 統合_複数アイテムの状態移動() throws {
        let container = try createInMemoryContainer()
        let context = container.mainContext

        let inboxRepository = InboxRepository(modelContext: context)
        let bookmarkRepository = BookmarkRepository(modelContext: context)

        // Given: 3つのInboxアイテム
        try inboxRepository.add(url: "https://example1.com", title: "Test1")
        try inboxRepository.add(url: "https://example2.com", title: "Test2")
        try inboxRepository.add(url: "https://example3.com", title: "Test3")

        let inboxItems = try context.fetch(FetchDescriptor<Inbox>())
        #expect(inboxItems.count == 3)

        // When: 2つをBookmarkへ、1つをArchiveへ移動
        try inboxRepository.moveToBookmark(inboxItems[0])
        try inboxRepository.moveToBookmark(inboxItems[1])
        try inboxRepository.moveToArchive(inboxItems[2])

        // Then: Inboxが空、Bookmark=2、Archive=1
        #expect(try context.fetch(FetchDescriptor<Inbox>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Bookmark>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<Archive>()).count == 1)
    }
}
```

**技術ポイント**:
- Swift Testing APIを使用
- 各Repository用に個別のテストファイルを作成
- 統合テストで状態移動の連鎖を検証
- `addedInboxAt`が正しく引き継がれることを検証

---

## 実装手順

### 1. ArchiveRepositoryProtocol.swiftを作成

**ファイルパス**: `ReadItLater/Domain/ArchiveRepositoryProtocol.swift`

Archive操作のためのプロトコルを新規作成します（上記のコード参照）。

### 2. ArchiveRepository.swiftを作成

**ファイルパス**: `ReadItLater/Infrastructure/ArchiveRepository.swift`

ArchiveRepositoryの実装を新規作成します（上記のコード参照）。

### 3. InboxRepositoryProtocol.swiftを更新

**ファイルパス**: `ReadItLater/Domain/InboxRepositoryProtocol.swift`

状態移動メソッドと削除メソッドを追加します（上記のコード参照）。

### 4. InboxRepository.swiftを更新

**ファイルパス**: `ReadItLater/Infrastructure/InboxRepository.swift`

状態移動ロジックと削除ロジックを実装します（上記のコード参照）。

### 5. BookmarkRepositoryProtocol.swiftを更新

**ファイルパス**: `ReadItLater/Domain/BookmarkRepositoryProtocol.swift`

状態移動メソッドを追加します（上記のコード参照）。

### 6. BookmarkRepository.swiftを更新

**ファイルパス**: `ReadItLater/Infrastructure/BookmarkRepository.swift`

状態移動ロジックを実装します（上記のコード参照）。

### 7. テストを追加・作成

既存のテストファイルにテストを追加し、新規テストファイルを作成します：

**既存ファイルに追加**:
- `ReadItLaterTests/Infrastructure/InboxRepositoryTests.swift`（状態移動テストを追加）
- `ReadItLaterTests/Infrastructure/BookmarkRepositoryTests.swift`（状態移動テストを追加）

**新規作成**:
- `ReadItLaterTests/Infrastructure/ArchiveRepositoryTests.swift`
- `ReadItLaterTests/Infrastructure/RepositoryIntegrationTests.swift`

---

## 修正対象ファイル一覧

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `Domain/InboxRepositoryProtocol.swift` | 状態移動メソッドと削除メソッドを追加 |
| `Infrastructure/InboxRepository.swift` | 状態移動ロジックと削除ロジックを実装 |
| `Domain/BookmarkRepositoryProtocol.swift` | 状態移動メソッドを追加 |
| `Infrastructure/BookmarkRepository.swift` | 状態移動ロジックを実装 |

### 新規ファイル

| ファイル | 目的 |
|---------|------|
| `Domain/ArchiveRepositoryProtocol.swift` | Archive操作のプロトコル定義 |
| `Infrastructure/ArchiveRepository.swift` | ArchiveRepositoryの実装 |
| `ReadItLaterTests/Infrastructure/ArchiveRepositoryTests.swift` | ArchiveRepositoryのテスト |
| `ReadItLaterTests/Infrastructure/RepositoryIntegrationTests.swift` | 状態移動の統合テスト |

### テスト追加ファイル

| ファイル | 変更内容 |
|---------|---------|
| `ReadItLaterTests/Infrastructure/InboxRepositoryTests.swift` | 状態移動テストを追加 |
| `ReadItLaterTests/Infrastructure/BookmarkRepositoryTests.swift` | 状態移動テストを追加 |

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

#### InboxRepositoryTests
- ✅ Inboxに追加できる
- ✅ Inbox上限チェック
- ✅ Inbox上限到達時はエラー
- ✅ InboxからBookmarkへ移動
- ✅ InboxからArchiveへ移動
- ✅ Inbox削除操作

#### BookmarkRepositoryTests
- ✅ BookmarkからArchiveへ移動

#### ArchiveRepositoryTests
- ✅ ArchiveからBookmarkへ移動
- ✅ Archive削除操作

#### RepositoryIntegrationTests
- ✅ addedInboxAtが全移動で保持される

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

### Xcode上でファイルが見つからない

**原因**: 新規作成したファイルがXcodeプロジェクトに追加されていない

**対策**:
1. Xcodeでファイルを右クリック → "Add Files to ReadItLater..."
2. または、プロジェクトナビゲータでグループを右クリック → "New File..."から作成

---

## 次のステップ

008の実装完了後、以下の順序で機能を追加していきます：

1. **009: UI実装** - 3タブUIとスワイプアクションを実装し、エンドユーザーが操作可能に

---

## 技術的補足

### 個別Repository方式を採用した理由

007で`InboxRepository`と`BookmarkRepository`を個別に作成した設計を踏襲しています。

**個別Repository方式のメリット**:
- 単一責任の原則に従う（各Repositoryが1つのモデルのみを担当）
- テストが書きやすい（モックの作成が容易）
- 各モデルの操作が独立して進化できる
- 既存コードとの整合性が高い

**統合Repository方式との比較**:
- 統合方式：1つの`URLItemRepository`で3モデルを扱う
  - メリット：状態移動が1箇所で完結
  - デメリット：責務が多く、テストが複雑になる
- 個別方式：3つのRepositoryで各モデルを扱う
  - メリット：責務が明確、テストが簡潔
  - デメリット：状態移動の実装が複数箇所に分散

**設計判断**:
007で既に個別Repository方式で実装されているため、一貫性を保つために008でも同じパターンを採用しています。

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
