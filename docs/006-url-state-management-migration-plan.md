# URL状態管理（Inbox/Bookmark/Archive）SwiftDataマイグレーション計画

## 背景と目的

ReadItLaterアプリに「**あとで読む**」機能特有の課題である**URLのためっぱなし問題**に対処するため、3つの状態管理概念を導入します。

### 解決したい問題
- URLを保存しても読まずに蓄積され続ける
- 本当に見たいURLが埋もれてしまう
- 整理する動機が生まれない

### 導入する概念

| 状態 | 説明 | 目的 |
|------|------|------|
| **inbox** | 全URLが最初に入る場所 | 最大50件制限で整理を促す |
| **bookmark** | 定期的に見たいURL | 長期保存用の分類先 |
| **archive** | 読み終わったURL | 読了後の分類先 |

---

## 設計の検討

### モデル設計の選択肢

プロジェクトの初期段階で、2つのアプローチを比較検討しました。

#### 選択肢A: 単一モデル + 状態enum

```swift
@Model class Bookmark {
    var url: String?
    var statusRawValue: String = "inbox"  // inbox/bookmark/archive
    var status: BookmarkStatus { get set }
}
```

**メリット**:
- 状態移動が単純なプロパティ更新（`bookmark.status = .archive`）
- CloudKit同期が安定（同一レコードの更新）
- 全URL検索が容易（単一テーブル）
- マイグレーションがシンプル（既存データにデフォルト値適用）

**デメリット**:
- 状態ごとに専用プロパティが多数必要な場合、nilだらけになる
- 型安全性が低い（間違った状態のオブジェクトを渡してもコンパイルエラーにならない）

#### 選択肢B: 別モデル方式（採用）

```swift
@Model class Inbox { var url: String?; var title: String?; ... }
@Model class Bookmark { var url: String?; var title: String?; ... }
@Model class Archive { var url: String?; var title: String?; ... }
```

**メリット**:
- 型安全性が高い（コンパイル時にバグを検出）
- 各状態で完全に異なるプロパティを持てる
- 概念的な分離が明確（設計思想に合致）
- 状態固有の機能実装が自然

**デメリット**:
- 状態移動時にデータのコピー＆削除が必要
- CloudKit同期での競合リスク（削除と作成のタイミング）
- 共通プロパティの定義が重複

### 採用理由

**別モデル方式**を採用した理由：

1. **3つの状態は本質的に異なる概念**
   - タブ分離はUI上の問題だけでなく、アプリとして別の概念として扱う
   - Inbox、Bookmark、Archiveは異なる目的と責務を持つ

2. **状態固有の機能が大きく異なる**
   - **Inbox**: 上限制限、経過日数表示、未読強調、リマインダー通知
   - **Bookmark**: 最終閲覧日、閲覧回数、ランダムピックアップ
   - **Archive**: 読了日記録、全文検索、Webページ内容保存

   これらは単一モデルでは扱いにくく、状態固有のプロパティが多数必要

3. **型安全性によるバグ防止**
   - `func sendReminder(for inbox: Inbox)` → Inboxのみ受け付ける
   - `func searchFullText(in archives: [Archive])` → Archiveのみ受け付ける
   - コンパイル時に型エラーを検出できる

4. **将来の拡張性**
   - 各モデルが独立して進化できる
   - Archiveに大量のプロパティを追加してもInbox/Bookmarkに影響しない

### CloudKit同期の対策

別モデル方式の懸念点である「削除＋作成での競合リスク」は、以下の設計で対策：

1. **基本的にオンライン使用を想定**（ユーザー要件）
2. **シンプルな物理削除**を採用（複雑な論理削除は避ける）
3. **競合発生は稀**：1日5件程度の操作頻度、オフライン利用は少ない
4. **影響は限定的**：競合が起きても1件のみ、URLは外部に存在するため再取得可能

→ **シンプルさを優先し、過剰な対策は避ける**

---

## マイグレーション仕様

### 現在のスキーマ構造

```swift
// AppV2Schema (バージョン 2.0.0) - 現行
@Model
final class Bookmark {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var url: String?
    var title: String?
}
```

### 新しいスキーマ構造

```swift
// AppV3Schema (バージョン 3.0.0) - 新規
struct AppV3Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [
        Inbox.self,
        Bookmark.self,
        Archive.self
    ]
    static let versionIdentifier: Schema.Version = .init(3, 0, 0)

    /// Inbox: 新規追加されたURL（最大50件制限）
    @Model
    final class Inbox {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?

        // Inbox固有のプロパティ
        var lastRemindedAt: Date?
        var isRead: Bool = false

        init(id: UUID = UUID(), url: String, title: String, createdAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.createdAt = createdAt
        }
    }

    /// Bookmark: 定期的に見たいURL
    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?

        // Bookmark固有のプロパティ
        var lastViewedAt: Date?
        var viewCount: Int = 0

        init(id: UUID = UUID(), url: String, title: String, createdAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.createdAt = createdAt
        }
    }

    /// Archive: 読み終わったURL
    @Model
    final class Archive {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?

        // Archive固有のプロパティ
        var archivedAt: Date = Date.now
        var fullTextContent: String?
        var readingNotes: String?

        init(id: UUID = UUID(), url: String, title: String, createdAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.createdAt = createdAt
        }
    }
}
```

### マイグレーション方式

**カスタムマイグレーション（Custom Migration）**を採用：

既存のBookmarkデータをInboxに移行する必要があるため、カスタムマイグレーションロジックを実装します。

```swift
struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self,
        AppV3Schema.self  // 追加
    ]

    static let stages: [MigrationStage] = [
        // V2 → V3: 既存のBookmarkをInboxに移行
        MigrationStage.custom(
            fromVersion: AppV2Schema.self,
            toVersion: AppV3Schema.self,
            willMigrate: nil,
            didMigrate: { context in
                // 既存のBookmarkを全て取得
                let bookmarks = try context.fetch(FetchDescriptor<AppV2Schema.Bookmark>())

                // 各BookmarkをInboxとして新規作成
                for oldBookmark in bookmarks {
                    let inbox = AppV3Schema.Inbox(
                        id: oldBookmark.id,  // 同じIDを維持
                        url: oldBookmark.url ?? "",
                        title: oldBookmark.title ?? "",
                        createdAt: oldBookmark.createdAt
                    )
                    context.insert(inbox)
                }

                // 古いBookmarkは自動的に削除される
                try context.save()
            }
        )
    ]
}
```

### 既存データの扱い

**設計決定**:
- 既存の全ブックマークは**Inbox**として移行
- 理由: 新機能導入として、ユーザーに分類を促す
- 元のIDを維持することで、CloudKitの追跡を継続

**重要な注意点**:
- V2のBookmarkモデルは完全に削除され、V3では3つの別モデルになる
- CloudKit上では既存のBookmarkレコードが更新される形で同期される
- ユーザーは初回起動時に全てのURLがInboxに入っていることを確認できる

---

## 実装手順

### Phase 1: スキーマ定義

#### 1.1 Migration/VersionedSchema.swift

**変更内容**: `AppV3Schema`に3つの別モデル（Inbox, Bookmark, Archive）を追加

```swift
struct AppV3Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [
        Inbox.self,
        Bookmark.self,
        Archive.self
    ]
    static let versionIdentifier: Schema.Version = .init(3, 0, 0)

    @Model
    final class Inbox {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?
        var lastRemindedAt: Date?
        var isRead: Bool = false

        init(id: UUID = UUID(), url: String, title: String, createdAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.createdAt = createdAt
        }
    }

    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?
        var lastViewedAt: Date?
        var viewCount: Int = 0

        init(id: UUID = UUID(), url: String, title: String, createdAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.createdAt = createdAt
        }
    }

    @Model
    final class Archive {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?
        var archivedAt: Date = Date.now
        var fullTextContent: String?
        var readingNotes: String?

        init(id: UUID = UUID(), url: String, title: String, createdAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.createdAt = createdAt
        }
    }
}
```

**技術ポイント**:
- 3つの独立したモデルで型安全性を確保
- 各モデルは状態固有のプロパティを持つ
- シンプルな設計で理解しやすい

#### 1.2 Migration/MigrationPlan.swift

**変更内容**: schemas配列に`AppV3Schema`を追加し、カスタムマイグレーションを実装

```swift
struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self,
        AppV3Schema.self
    ]

    static let stages: [MigrationStage] = [
        MigrationStage.custom(
            fromVersion: AppV2Schema.self,
            toVersion: AppV3Schema.self,
            willMigrate: nil,
            didMigrate: { context in
                let bookmarks = try context.fetch(FetchDescriptor<AppV2Schema.Bookmark>())
                for oldBookmark in bookmarks {
                    let inbox = AppV3Schema.Inbox(
                        id: oldBookmark.id,
                        url: oldBookmark.url ?? "",
                        title: oldBookmark.title ?? "",
                        createdAt: oldBookmark.createdAt
                    )
                    context.insert(inbox)
                }
                try context.save()
            }
        )
    ]
}
```

---

### Phase 2: ドメイン層更新

#### 2.1 Domain/ModelExtensions.swift（新規）

**ファイル作成**: 各モデルのtype aliasと共通extensionを定義

```swift
//
//  ModelExtensions.swift
//  ReadItLater
//

import Foundation

/// 現在のスキーマバージョンのモデルへのtype alias
typealias Inbox = AppV3Schema.Inbox
typealias Bookmark = AppV3Schema.Bookmark
typealias Archive = AppV3Schema.Archive

/// 共通プロトコル: URLを持つアイテム
protocol URLItem {
    var id: UUID { get }
    var url: String? { get }
    var title: String? { get }
    var createdAt: Date { get }
}

extension Inbox: URLItem {}
extension Bookmark: URLItem {}
extension Archive: URLItem {}

/// URLItemの共通extension
extension URLItem {
    var safeTitle: String {
        title ?? "No title"
    }

    var maybeURL: URL? {
        URL(string: url ?? "")
    }
}
```

**技術ポイント**:
- `URLItem`プロトコルで共通インターフェースを定義
- 各モデルのtype aliasを一箇所で管理
- 共通の便利メソッドをextensionで提供

#### 2.2 Domain/InboxConfiguration.swift（新規）

**ファイル作成**: inbox機能の設定値を定義

```swift
//
//  InboxConfiguration.swift
//  ReadItLater
//

import Foundation

/// Inboxの設定値
enum InboxConfiguration {
    /// inbox内の最大保存数
    static let maxItems: Int = 50

    /// 警告を表示する閾値（最大数の80%）
    static var warningThreshold: Int {
        Int(Double(maxItems) * 0.8)
    }
}
```

#### 2.3 Domain/URLItemRepositoryProtocol.swift（BookmarkRepositoryProtocolから改名）

**変更内容**: 別モデル方式に対応したリポジトリプロトコルに変更

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
- 各モデルを明示的に型指定
- 状態移動のメソッドを型安全に定義

---

### Phase 3: Infrastructure層更新

#### 3.1 Infrastructure/URLItemRepository.swift（BookmarkRepositoryから改名）

**変更内容**: 別モデル方式の状態移動ロジックを実装

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

    func addToInbox(url: String, title: String) throws {
        guard canAddToInbox() else {
            throw RepositoryError.inboxFull
        }

        let inbox = Inbox(url: url, title: title)
        modelContext.insert(inbox)
        try modelContext.save()
    }

    func canAddToInbox() -> Bool {
        remainingInboxCapacity() > 0
    }

    func inboxCount() -> Int {
        let descriptor = FetchDescriptor<Inbox>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func remainingInboxCapacity() -> Int {
        max(0, InboxConfiguration.maxItems - inboxCount())
    }

    // MARK: - 状態移動

    func moveToBookmark(_ inbox: Inbox) throws {
        let bookmark = Bookmark(
            url: inbox.url ?? "",
            title: inbox.title ?? "",
            createdAt: inbox.createdAt
        )

        modelContext.insert(bookmark)
        modelContext.delete(inbox)
        try modelContext.save()
    }

    func moveToArchive(_ inbox: Inbox) throws {
        let archive = Archive(
            url: inbox.url ?? "",
            title: inbox.title ?? "",
            createdAt: inbox.createdAt
        )

        modelContext.insert(archive)
        modelContext.delete(inbox)
        try modelContext.save()
    }

    func moveToArchive(_ bookmark: Bookmark) throws {
        let archive = Archive(
            url: bookmark.url ?? "",
            title: bookmark.title ?? "",
            createdAt: bookmark.createdAt
        )

        modelContext.insert(archive)
        modelContext.delete(bookmark)
        try modelContext.save()
    }

    func moveToBookmark(_ archive: Archive) throws {
        let bookmark = Bookmark(
            url: archive.url ?? "",
            title: archive.title ?? "",
            createdAt: archive.createdAt
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

enum RepositoryError: LocalizedError {
    case inboxFull

    var errorDescription: String? {
        switch self {
        case .inboxFull:
            return "Inboxが上限に達しています"
        }
    }
}
```

**技術ポイント**:
- 状態移動は「新規作成 + 削除」のシンプルな実装
- `createdAt`を引き継ぐことで元の追加日時を保持
- 型安全性により、誤った移動を防止

---

### Phase 4: Share Extension更新

#### 4.1 ShareExtension/ShareViewController.swift

**変更内容**: Inbox上限チェックと別モデル方式に対応

```swift
private func saveBookmark(url: String, title: String?) async throws {
    guard let container = modelContainer else {
        throw ShareError.containerInitFailed
    }

    let context = ModelContext(container)
    let repository = URLItemRepository(modelContext: context)

    // Inbox上限チェック
    guard repository.canAddToInbox() else {
        throw ShareError.inboxFull
    }

    // URL検証
    let result = Bookmark.create(from: url, title: title)

    switch result {
    case .success(let bookmarkData):
        // Inboxに追加
        try repository.addToInbox(
            url: bookmarkData.url,
            title: bookmarkData.title
        )

    case .failure(let error):
        throw ShareError.bookmarkCreationFailed(error)
    }
}
```

**ShareErrorの拡張**:

```swift
enum ShareError: LocalizedError {
    case noURLFound
    case containerInitFailed
    case bookmarkCreationFailed(Bookmark.CreationError)
    case inboxFull

    var errorDescription: String? {
        switch self {
        case .noURLFound:
            return "URLが見つかりませんでした"
        case .containerInitFailed:
            return "データベースの初期化に失敗しました"
        case .bookmarkCreationFailed(let error):
            return "ブックマークの作成に失敗しました: \(error.localizedDescription)"
        case .inboxFull:
            return "Inboxが上限（\(InboxConfiguration.maxItems)件）に達しています。既存のアイテムを整理してください。"
        }
    }
}
```

**技術ポイント**:
- Share ExtensionからはInboxにのみ追加
- Repository経由で上限チェックと追加を実行
- エラーメッセージに上限数を表示

---

### Phase 5: テスト

#### 5.1 ReadItLaterTests/Infrastructure/URLItemRepositoryTests.swift

**新規テストケース**:

```swift
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
            for: AppV3Schema.self,
            migrationPlan: AppMigrationPlan.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        repository = URLItemRepository(modelContext: modelContext)
    }

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

    @Test("InboxからBookmarkへ移動")
    func moveInboxToBookmark() throws {
        // Given: Inboxアイテム
        try repository.addToInbox(url: "https://example.com", title: "Test")
        let inboxDescriptor = FetchDescriptor<Inbox>()
        let inbox = try modelContext.fetch(inboxDescriptor).first!

        // When: Bookmarkへ移動
        try repository.moveToBookmark(inbox)

        // Then: Bookmarkに存在し、Inboxから削除
        let bookmarkDescriptor = FetchDescriptor<Bookmark>()
        let bookmarks = try modelContext.fetch(bookmarkDescriptor)
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.url == "https://example.com")

        let remainingInbox = try modelContext.fetch(inboxDescriptor)
        #expect(remainingInbox.isEmpty)
    }

    @Test("InboxからArchiveへ移動")
    func moveInboxToArchive() throws {
        // Given: Inboxアイテム
        try repository.addToInbox(url: "https://example.com", title: "Test")
        let inbox = try modelContext.fetch(FetchDescriptor<Inbox>()).first!

        // When: Archiveへ移動
        try repository.moveToArchive(inbox)

        // Then: Archiveに存在
        let archives = try modelContext.fetch(FetchDescriptor<Archive>())
        #expect(archives.count == 1)
        #expect(archives.first?.url == "https://example.com")
    }

    @Test("BookmarkからArchiveへ移動")
    func moveBookmarkToArchive() throws {
        // Given: Inboxからbookmarkを作成
        try repository.addToInbox(url: "https://example.com", title: "Test")
        let inbox = try modelContext.fetch(FetchDescriptor<Inbox>()).first!
        try repository.moveToBookmark(inbox)
        let bookmark = try modelContext.fetch(FetchDescriptor<Bookmark>()).first!

        // When: Archiveへ移動
        try repository.moveToArchive(bookmark)

        // Then: Archiveに存在
        let archives = try modelContext.fetch(FetchDescriptor<Archive>())
        #expect(archives.count == 1)
        #expect(archives.first?.url == "https://example.com")
    }

    @Test("削除操作")
    func deleteItems() throws {
        // Given: 各タイプのアイテム
        try repository.addToInbox(url: "https://example.com/1", title: "Test1")
        let inbox = try modelContext.fetch(FetchDescriptor<Inbox>()).first!
        try repository.moveToBookmark(inbox)
        let bookmark = try modelContext.fetch(FetchDescriptor<Bookmark>()).first!

        // When: 削除
        repository.delete(bookmark)

        // Then: 削除される
        let bookmarks = try modelContext.fetch(FetchDescriptor<Bookmark>())
        #expect(bookmarks.isEmpty)
    }
}
```

**技術ポイント**:
- Swift Testing APIを使用
- 別モデル方式の状態移動をテスト
- データが正しく移行されることを検証
- 型安全性が保証されることを確認

---

## 修正対象ファイル一覧

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `Migration/VersionedSchema.swift` | AppV3Schemaに3つのモデル（Inbox, Bookmark, Archive）を追加 |
| `Migration/MigrationPlan.swift` | AppV3Schemaとカスタムマイグレーションロジックを追加 |
| `ShareExtension/ShareViewController.swift` | Inbox上限チェックと別モデル方式に対応 |
| `ReadItLaterApp.swift` | ModelContainerの設定を3モデルに更新 |

### 新規ファイル

| ファイル | 目的 |
|---------|------|
| `Domain/ModelExtensions.swift` | 3モデルのtype aliasと共通プロトコル定義 |
| `Domain/InboxConfiguration.swift` | Inbox上限設定 |
| `Domain/URLItemRepositoryProtocol.swift` | 別モデル方式のリポジトリプロトコル |
| `Infrastructure/URLItemRepository.swift` | 状態移動ロジック実装 |
| `ReadItLaterTests/Infrastructure/URLItemRepositoryTests.swift` | 状態移動と上限チェックのテスト |

### 削除または大幅変更が必要なファイル

| ファイル | 理由 |
|---------|------|
| `Domain/BookmarkExtensions.swift` | ModelExtensions.swiftに統合または削除 |
| `Domain/BookmarkData.swift` | 別モデル方式では不要になる可能性 |
| `Domain/BookmarkRepositoryProtocol.swift` | URLItemRepositoryProtocolに置き換え |
| `Infrastructure/BookmarkRepository.swift` | URLItemRepositoryに置き換え |
| `View/ContentView.swift` | 3つの別モデルを扱うよう大幅変更 |
| `Presentation/AddBookmarkViewModel.swift` | Inbox追加ロジックに変更 |

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

### 動作確認項目

1. **マイグレーション確認**
   - 既存アプリをアップデート後、全ブックマークがinbox状態になっていることを確認
   - アプリがクラッシュせずに起動することを確認

2. **新規追加確認**
   - Share Extensionから追加したURLがinboxに入ることを確認

3. **上限テスト**
   - inbox内に50件のURLを追加
   - 51件目を追加しようとするとエラーメッセージが表示されることを確認

4. **状態移動確認**
   - inbox → bookmark への移動が正常に動作
   - inbox → archive への移動が正常に動作
   - 状態変更後、該当タブに表示されることを確認

---

## 技術的考慮事項

### CloudKit同期

**同期の仕組み**:
- 各モデル（Inbox, Bookmark, Archive）は独立したCloudKitレコードタイプとして同期
- 状態移動時は「削除 + 作成」の2操作として同期される
- `createdAt`を引き継ぐことで元の追加日時を保持

**競合リスクと対策**:
- **競合発生条件**: オフライン時に同じアイテムを別デバイスで編集＋状態移動
- **発生確率**: 基本的にオンライン使用のため極めて稀（月に1回未満）
- **影響範囲**: 最悪の場合、1件のURLの編集内容が消失
- **許容理由**: URLは外部に存在するため再取得可能、個人用途で影響は限定的

**シンプルな設計の選択**:
- 論理削除やトランザクションテーブルは採用しない
- 過剰な対策よりも実装のシンプルさを優先
- 将来問題が顕在化した場合に対策を検討

### マイグレーション

**カスタムマイグレーション**:
- V2のBookmarkを全てInboxに変換
- 元のIDを維持してCloudKit追跡を継続
- `didMigrate`クロージャで変換ロジックを実装

### パフォーマンス

**クエリ効率**:
- 各モデルは独立したテーブルとして管理
- `@Query`は型ごとに最適化されたインデックスを利用
- `fetchCount`は全件取得せずカウントのみ取得

**データサイズ**:
- Archiveの`fullTextContent`は大きくなる可能性あり
- 将来的に全文検索用インデックスの最適化が必要になる可能性

### UI実装の方針

**ContentView.swiftの実装例**:
```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // 各モデルを独立してクエリ
    @Query private var inboxItems: [Inbox]
    @Query private var bookmarkItems: [Bookmark]
    @Query private var archiveItems: [Archive]

    private var repository: URLItemRepository {
        URLItemRepository(modelContext: modelContext)
    }

    var body: some View {
        TabView {
            InboxView(items: inboxItems, repository: repository)
                .tabItem { Label("Inbox", systemImage: "tray") }

            BookmarkView(items: bookmarkItems, repository: repository)
                .tabItem { Label("Bookmarks", systemImage: "bookmark") }

            ArchiveView(items: archiveItems, repository: repository)
                .tabItem { Label("Archive", systemImage: "archivebox") }
        }
    }
}
```

**各Viewの実装例（InboxView）**:
```swift
struct InboxView: View {
    let items: [Inbox]
    let repository: URLItemRepository
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { inbox in
                    InboxRow(inbox: inbox)
                        .swipeActions(edge: .leading) {
                            Button("Bookmark") {
                                try? repository.moveToBookmark(inbox)
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Archive") {
                                try? repository.moveToArchive(inbox)
                            }
                            .tint(.green)

                            Button("Delete", role: .destructive) {
                                repository.delete(inbox)
                            }
                        }
                }
            }
            .navigationTitle("Inbox (\(items.count)/\(InboxConfiguration.maxItems))")
            .toolbar {
                Button(action: { showingAddSheet = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
    }
}
```

**型安全性の活用**:
```swift
// コンパイル時に型チェック
func sendReminder(for inbox: Inbox) {
    // Inboxのみ受け付ける
}

func searchFullText(in archives: [Archive], query: String) -> [Archive] {
    // Archiveのみ受け付ける
}
```

---

## 実装フロー

```
[アプリ起動]
    ↓
AppMigrationPlan実行
    ↓ V2 → V3へカスタムマイグレーション
    ↓ 既存BookmarkをInboxに変換（IDは維持）
    ↓
[マイグレーション完了]
    ↓
ContentView表示
    ↓ @Query で各モデルを独立取得
    ↓
[各タブに型別URLを表示]
    - Inbox: 最大50件制限、Inboxモデル
    - Bookmarks: 無制限、Bookmarkモデル
    - Archive: 無制限、Archiveモデル

[Share Extensionからの追加]
    ↓
repository.canAddToInbox()チェック
    ↓ true → Inboxモデルとして追加
    ↓ false → ShareError.inboxFull
    ↓
[Inboxに追加 or エラー表示]

[状態移動の流れ（例: Inbox → Archive）]
    ↓
ユーザーがスワイプアクション
    ↓
repository.moveToArchive(inbox)
    ↓
1. Archiveモデルを作成（createdAtを引き継ぐ）
2. Inboxモデルを削除
3. modelContext.save()
    ↓
CloudKit同期: 削除 + 作成の2操作
    ↓
[他デバイスに反映]
```

---

## 議論の記録

### 設計アプローチの検討過程

**初期提案**: 単一モデル + 状態enum方式
- メリット: 状態移動がシンプル、CloudKit同期が安定
- デメリット: 状態固有プロパティが増えるとnilだらけになる

**ユーザーからの懸念**:
1. 「3つはそれぞれ別のタブから閲覧するイメージ。単一モデルだと今後の機能追加が苦しくならないか？」
2. 各状態で大きく異なる機能が必要（Inbox: リマインダー、Bookmark: ランダム選択、Archive: 全文検索）
3. 型安全性の重要性

**再検討の結果**: 別モデル方式を採用
- 理由1: 3つの状態は本質的に異なる概念として扱うべき
- 理由2: 状態固有の機能が大きく異なり、単一モデルでは扱いにくい
- 理由3: 型安全性によるバグ防止のメリットが大きい
- 理由4: CloudKit同期リスクは使用パターン上許容可能

### CloudKit同期対策の検討

**検討した対策**:
1. 論理削除（Soft Delete）→ データ蓄積、実装複雑
2. トランザクションテーブル → 実装複雑、ストレージ消費
3. 同一ID維持 + 参照 → 完全な競合回避は不可
4. 物理削除 + ユーザー警告 → オフライン時の操作制限
5. シンプルな物理削除 → **採用**

**採用理由**:
- 基本的にオンライン使用（ユーザー要件）
- 競合発生は稀（1日5件程度の操作、オフライン利用少ない）
- 影響は限定的（1件のみ、URLは再取得可能）
- シンプルさを優先し、過剰な対策は避ける
- 将来問題が起きたら対策を追加できる設計

### ユーザーの設計決定

| 項目 | 選択肢 | 決定 | 理由 |
|------|--------|------|------|
| モデル設計 | 単一 / 別モデル | **別モデル** | 概念的分離、型安全性、状態固有機能 |
| CloudKit対策 | 論理削除 / 物理削除 | **物理削除** | シンプルさ優先、リスクは許容範囲 |
| 既存データの扱い | inbox / bookmark | **inbox** | 新機能として分類を促す |
| inbox上限 | 50 / 100 / 200 | **50件** | こまめな整理を促進 |
| 上限到達時の動作 | 拒否 / 自動アーカイブ | **拒否** | シンプルでユーザーの意思を尊重 |

---

## アーキテクチャの利点

### 別モデル方式のメリット

**型安全性**:
- コンパイル時に型エラーを検出
- `func sendReminder(for inbox: Inbox)`のように、誤った型を渡せない
- リファクタリングが安全（型チェックでエラー検出）

**概念的明確性**:
- Inbox、Bookmark、Archiveは本質的に異なる概念
- コードを読んだときに意図が明確
- 各モデルが独立して進化できる

**状態固有機能の実装が自然**:
- Inboxのみリマインダー機能
- Bookmarkのみランダムピックアップ
- Archiveのみ全文検索
- 各機能を該当モデルのextensionで実装

**パフォーマンス最適化**:
- 各モデルは独立したテーブル
- Archiveの全文検索がInbox/Bookmarkに影響しない
- 将来的なインデックス最適化が容易

### シンプルな実装

**物理削除の利点**:
- 論理削除フラグ不要
- クエリに`isDeleted`フィルタ不要
- データが蓄積しない
- コードが理解しやすい

**日時情報の保持**:
- `createdAt`で元の追加日時を保持
- `archivedAt`でアーカイブした日時を記録
- 経過日数の計算が可能

### ためっぱなし防止機能の実現

**Inbox 50件制限**:
- 上限到達で整理を促進
- 残り件数表示でユーザーに認識させる
- シンプルな拒否方式（自動削除なし）

**状態移動の容易さ**:
- スワイプアクションで直感的に移動
- 3つの分類先で整理の選択肢を提供
- 型安全性により誤操作を防止

---

## 実装予定日: 2026-01-17
