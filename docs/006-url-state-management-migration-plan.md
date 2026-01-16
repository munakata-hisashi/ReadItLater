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

#### 選択肢A: 別モデル方式

```swift
@Model class Inbox { var url: String?; var title: String?; ... }
@Model class Bookmark { var url: String?; var title: String?; ... }
@Model class Archive { var url: String?; var title: String?; ... }
```

**メリット**:
- 型安全性が高い
- 各状態で完全に異なるプロパティを持てる

**デメリット**:
- 状態移動時にデータのコピー＆削除が必要
- CloudKit同期の複雑化（削除と作成のタイミングでデータ消失リスク）
- コードの重複（同じプロパティを3つのモデルで定義）
- 全URL一覧取得時に3モデルの結合が必要

#### 選択肢B: 単一モデル + 状態enum（採用）

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
- 状態ごとに専用プロパティが多数必要になった場合、nilが増える

### 採用理由

**単一モデル + 状態enum**を採用した理由：

1. **現在の要件では各状態で同じ情報を持つ**
   - url, title, createdAtのみで3状態とも同じ構造
   - 状態固有のプロパティは現時点で予定なし

2. **主目的は「ためっぱなし防止」**
   - 必要なのは「状態の区別」だけ
   - 複雑なデータ構造の違いは不要

3. **将来の拡張性**
   - 状態固有プロパティが必要になった場合でも対応可能
   - 選択肢A: Bookmarkに追加（他の状態ではnil）
   - 選択肢B: その時点で別モデルに分離するマイグレーション

4. **CloudKit同期の安定性**
   - 別モデル方式での削除＋作成は同期タイミングのリスクあり
   - プロパティ更新のみなら安全

### ユーザーからの懸念と回答

**懸念**: 「3つはそれぞれ別のタブから閲覧するイメージ。単一モデルだと今後の機能追加が苦しくならないか？」

**回答**: 単一モデルでも以下は問題なく実現可能：
- タブ分離表示 → `@Query(filter:)`で状態フィルター
- 状態固有の表示ロジック → View側で`switch status`分岐
- 状態固有の計算プロパティ → `extension`で追加
- ソート順の違い → 各タブで異なる`SortDescriptor`

将来「Archiveだけに読了日・評価・メモが必要」など、状態固有の多数のプロパティが必要になった時点で、別モデルへの分離を検討すれば良い。

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
/// ブックマークの状態enum
enum BookmarkStatus: String, Codable, CaseIterable {
    case inbox = "inbox"
    case bookmark = "bookmark"
    case archive = "archive"
}

// AppV3Schema (バージョン 3.0.0) - 新規
struct AppV3Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [Bookmark.self]
    static let versionIdentifier: Schema.Version = .init(3, 0, 0)

    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?

        // 新規追加プロパティ
        var statusRawValue: String = BookmarkStatus.inbox.rawValue
        var statusChangedAt: Date = Date.now

        // 型安全なアクセス用computed property
        var status: BookmarkStatus {
            get { BookmarkStatus(rawValue: statusRawValue) ?? .inbox }
            set {
                statusRawValue = newValue.rawValue
                statusChangedAt = Date.now
            }
        }
    }
}
```

### マイグレーション方式

**軽量マイグレーション（Lightweight Migration）**を採用：

- 新規プロパティにデフォルト値を設定
- SwiftDataが自動的に既存データを変換
- `stages`配列は空のまま（カスタムマイグレーションロジック不要）

```swift
struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self,
        AppV3Schema.self  // 追加
    ]
    static let stages: [MigrationStage] = []  // 空 = 軽量マイグレーション
}
```

### 既存データの扱い

**設計決定**（ユーザー選択）:
- 既存の全ブックマークは**inbox状態**に移行
- 理由: 新機能導入として、ユーザーに分類を促す

**代替案**:
- `bookmark`状態に移行 → 既存ユーザー体験を変えないが、新機能の意味が薄れる

---

## 実装手順

### Phase 1: スキーマ定義

#### 1.1 Migration/VersionedSchema.swift

**変更内容**: `BookmarkStatus` enumと`AppV3Schema`を追加

```swift
/// ブックマークの状態を表すenum
/// - inbox: 新規追加されたURL、最大50件制限あり
/// - bookmark: 定期的に見たいURL
/// - archive: 読み終わったURL
enum BookmarkStatus: String, Codable, CaseIterable {
    case inbox = "inbox"
    case bookmark = "bookmark"
    case archive = "archive"

    var displayName: String {
        switch self {
        case .inbox: return "Inbox"
        case .bookmark: return "Bookmarks"
        case .archive: return "Archive"
        }
    }
}

struct AppV3Schema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [Bookmark.self]
    static let versionIdentifier: Schema.Version = .init(3, 0, 0)

    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var url: String?
        var title: String?
        var statusRawValue: String = BookmarkStatus.inbox.rawValue
        var statusChangedAt: Date = Date.now

        var status: BookmarkStatus {
            get { BookmarkStatus(rawValue: statusRawValue) ?? .inbox }
            set {
                statusRawValue = newValue.rawValue
                statusChangedAt = Date.now
            }
        }

        init(url: String, title: String = "", status: BookmarkStatus = .inbox) {
            self.url = url
            self.title = title
            self.statusRawValue = status.rawValue
            self.statusChangedAt = Date.now
        }
    }
}
```

**技術ポイント**:
- `statusRawValue: String`を永続化プロパティとして定義
- `status` computed propertyで型安全なアクセス提供
- `statusChangedAt`で状態変更履歴をトラッキング

#### 1.2 Migration/MigrationPlan.swift

**変更内容**: schemas配列に`AppV3Schema`を追加

```swift
struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self,
        AppV3Schema.self  // 追加
    ]
    static let stages: [MigrationStage] = []
}
```

---

### Phase 2: ドメイン層更新

#### 2.1 Domain/BookmarkExtensions.swift

**変更内容**: typealiasを`AppV3Schema.Bookmark`に更新、状態関連extensionを追加

```swift
/// 現在のスキーマバージョンのBookmarkモデルへのtype alias
typealias Bookmark = AppV3Schema.Bookmark

extension Bookmark {
    var safeTitle: String {
        title ?? "No title"
    }

    var maybeURL: URL? {
        URL(string: url ?? "")
    }

    /// 状態の表示名
    var statusDisplayName: String {
        status.displayName
    }
}
```

#### 2.2 Domain/InboxConfiguration.swift（新規）

**ファイル作成**: inbox機能の設定値を定義

```swift
//
//  InboxConfiguration.swift
//  ReadItLater
//
//  Inbox機能の設定値を定義
//

import Foundation

/// Inboxの設定値
enum InboxConfiguration {
    /// inbox内の最大保存数
    /// この数を超える場合は新規追加を拒否
    static let maxItems: Int = 50

    /// 警告を表示する閾値（最大数の80%）
    static var warningThreshold: Int {
        Int(Double(maxItems) * 0.8)
    }
}
```

**設計決定**（ユーザー選択）:
- 最大50件（100件、200件の選択肢から選択）
- 上限到達時は新規追加を拒否（自動アーカイブ方式は不採用）

#### 2.3 Domain/BookmarkData.swift

**変更内容**: `status`プロパティを追加

```swift
/// Bookmarkの作成時に使用するデータ転送オブジェクト
struct BookmarkData: Equatable {
    let url: String
    let title: String
    let status: BookmarkStatus  // 追加

    init(url: String, title: String, status: BookmarkStatus = .inbox) {
        self.url = url
        self.title = title
        self.status = status
    }
}
```

#### 2.4 Domain/BookmarkRepositoryProtocol.swift

**変更内容**: 状態管理メソッドを追加

```swift
protocol BookmarkRepositoryProtocol {
    // MARK: - 基本CRUD

    func add(_ bookmarkData: BookmarkData)
    func delete(_ bookmark: Bookmark)
    func delete(_ bookmarks: [Bookmark])

    // MARK: - 状態管理（新規追加）

    /// ブックマークの状態を更新
    func updateStatus(_ bookmark: Bookmark, to status: BookmarkStatus)

    /// 指定した状態のブックマーク数を取得
    func countByStatus(_ status: BookmarkStatus) -> Int

    /// inboxに追加可能かチェック
    func canAddToInbox() -> Bool

    /// inboxの残り枠数を取得
    func remainingInboxCapacity() -> Int
}
```

---

### Phase 3: Infrastructure層更新

#### 3.1 Infrastructure/BookmarkRepository.swift

**変更内容**: 状態管理メソッドを実装

```swift
final class BookmarkRepository: BookmarkRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 基本CRUD（既存）

    func add(_ bookmarkData: BookmarkData) {
        let newBookmark = Bookmark(
            url: bookmarkData.url,
            title: bookmarkData.title,
            status: bookmarkData.status  // status追加
        )
        modelContext.insert(newBookmark)
    }

    func delete(_ bookmark: Bookmark) {
        modelContext.delete(bookmark)
    }

    func delete(_ bookmarks: [Bookmark]) {
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
    }

    // MARK: - 状態管理（新規追加）

    func updateStatus(_ bookmark: Bookmark, to status: BookmarkStatus) {
        bookmark.status = status
        // SwiftDataは自動保存のため、明示的なsaveは不要
    }

    func countByStatus(_ status: BookmarkStatus) -> Int {
        let statusValue = status.rawValue
        let predicate = #Predicate<Bookmark> { $0.statusRawValue == statusValue }
        let descriptor = FetchDescriptor<Bookmark>(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func canAddToInbox() -> Bool {
        remainingInboxCapacity() > 0
    }

    func remainingInboxCapacity() -> Int {
        max(0, InboxConfiguration.maxItems - countByStatus(.inbox))
    }
}
```

**技術ポイント**:
- `#Predicate`でstatusRawValueを直接フィルター
- `fetchCount`は全件取得せずカウントのみ取得（パフォーマンス最適化）

---

### Phase 4: Share Extension更新

#### 4.1 ShareExtension/ShareViewController.swift

**変更内容**: inbox上限チェックを追加

```swift
private func saveBookmark(url: String, title: String?) async throws {
    guard let container = modelContainer else {
        throw ShareError.containerInitFailed
    }

    // inbox上限チェック（追加）
    let context = ModelContext(container)
    let repository = BookmarkRepository(modelContext: context)

    guard repository.canAddToInbox() else {
        throw ShareError.inboxFull
    }

    let result = Bookmark.create(from: url, title: title)

    switch result {
    case .success(let bookmarkData):
        let bookmark = Bookmark(
            url: bookmarkData.url,
            title: bookmarkData.title,
            status: .inbox  // 常にinboxに追加
        )
        context.insert(bookmark)
        try context.save()

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
    case inboxFull  // 追加

    var errorDescription: String? {
        switch self {
        case .noURLFound:
            return "URLが見つかりませんでした"
        case .containerInitFailed:
            return "データベースの初期化に失敗しました"
        case .bookmarkCreationFailed(let error):
            return "ブックマークの作成に失敗しました: \(error.localizedDescription)"
        case .inboxFull:
            return "Inboxが上限に達しています。既存のアイテムを整理してください。"
        }
    }
}
```

---

### Phase 5: テスト

#### 5.1 ReadItLaterTests/Infrastructure/BookmarkRepositoryTests.swift

**新規テストケース**:

```swift
final class BookmarkRepositoryStatusTests: XCTestCase {
    var modelContext: ModelContext!
    var repository: BookmarkRepository!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Bookmark.self,
            migrationPlan: AppMigrationPlan.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        repository = BookmarkRepository(modelContext: modelContext)
    }

    func testUpdateStatus() throws {
        // Given: inboxのブックマーク
        let bookmarkData = BookmarkData(
            url: "https://example.com",
            title: "Test",
            status: .inbox
        )
        repository.add(bookmarkData)

        let descriptor = FetchDescriptor<Bookmark>()
        let bookmarks = try modelContext.fetch(descriptor)
        let bookmark = try XCTUnwrap(bookmarks.first)

        // When: archiveに変更
        repository.updateStatus(bookmark, to: .archive)

        // Then: 状態が更新される
        XCTAssertEqual(bookmark.status, .archive)
    }

    func testCountByStatus() throws {
        // Given: 異なる状態のブックマーク
        repository.add(BookmarkData(url: "https://example.com/1", title: "1", status: .inbox))
        repository.add(BookmarkData(url: "https://example.com/2", title: "2", status: .inbox))
        repository.add(BookmarkData(url: "https://example.com/3", title: "3", status: .bookmark))

        // When & Then
        XCTAssertEqual(repository.countByStatus(.inbox), 2)
        XCTAssertEqual(repository.countByStatus(.bookmark), 1)
        XCTAssertEqual(repository.countByStatus(.archive), 0)
    }

    func testCanAddToInbox() throws {
        // Given: inbox上限未満
        for i in 0..<(InboxConfiguration.maxItems - 1) {
            repository.add(BookmarkData(
                url: "https://example.com/\(i)",
                title: "\(i)",
                status: .inbox
            ))
        }

        // When & Then: 追加可能
        XCTAssertTrue(repository.canAddToInbox())
        XCTAssertEqual(repository.remainingInboxCapacity(), 1)
    }

    func testCannotAddToInboxWhenFull() throws {
        // Given: inbox上限到達
        for i in 0..<InboxConfiguration.maxItems {
            repository.add(BookmarkData(
                url: "https://example.com/\(i)",
                title: "\(i)",
                status: .inbox
            ))
        }

        // When & Then: 追加不可
        XCTAssertFalse(repository.canAddToInbox())
        XCTAssertEqual(repository.remainingInboxCapacity(), 0)
    }
}
```

---

## 修正対象ファイル一覧

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `Migration/VersionedSchema.swift` | AppV3Schema, BookmarkStatus enum追加 |
| `Migration/MigrationPlan.swift` | schemas配列にAppV3Schema追加 |
| `Domain/BookmarkExtensions.swift` | typealiasをAppV3Schema.Bookmarkに更新 |
| `Domain/BookmarkData.swift` | statusプロパティ追加 |
| `Domain/BookmarkRepositoryProtocol.swift` | 状態管理メソッド追加 |
| `Infrastructure/BookmarkRepository.swift` | 状態管理実装追加 |
| `ShareExtension/ShareViewController.swift` | inbox上限チェック追加 |

### 新規ファイル

| ファイル | 目的 |
|---------|------|
| `Domain/InboxConfiguration.swift` | inbox上限設定 |
| `ReadItLaterTests/Infrastructure/BookmarkRepositoryStatusTests.swift` | 状態管理のテスト |

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
- `statusRawValue`はStringなのでCloudKitで自動同期
- `statusChangedAt`はDateなので同様に自動同期
- 競合時はSwiftDataのデフォルト動作（最終更新優先）に従う

### 後方互換性
- 既存データはデフォルト値（inbox）が自動適用
- 軽量マイグレーションによりアプリ更新時に自動移行
- ユーザー操作不要

### パフォーマンス
- `@Query(filter:)`は効率的にインデックスを利用
- `fetchCount`は全件取得せずカウントのみ取得
- 状態フィルターは各タブで独立して実行

### UI実装の方針

**ContentView.swiftの実装例**:
```swift
// 各状態のブックマークを取得
@Query(filter: #Predicate<Bookmark> { $0.statusRawValue == "inbox" })
private var inboxBookmarks: [Bookmark]

@Query(filter: #Predicate<Bookmark> { $0.statusRawValue == "bookmark" })
private var savedBookmarks: [Bookmark]

@Query(filter: #Predicate<Bookmark> { $0.statusRawValue == "archive" })
private var archivedBookmarks: [Bookmark]

// タブビューで切り替え
TabView {
    InboxView(bookmarks: inboxBookmarks)
        .tabItem { Label("Inbox", systemImage: "tray") }

    BookmarkView(bookmarks: savedBookmarks)
        .tabItem { Label("Bookmarks", systemImage: "bookmark") }

    ArchiveView(bookmarks: archivedBookmarks)
        .tabItem { Label("Archive", systemImage: "archivebox") }
}
```

---

## 実装フロー

```
[アプリ起動]
    ↓
AppMigrationPlan実行
    ↓ V2 → V3へ軽量マイグレーション
    ↓ 既存データにstatusRawValue = "inbox"、statusChangedAt = Date.now追加
    ↓
[マイグレーション完了]
    ↓
ContentView表示
    ↓ @Query(filter:)で状態別フィルター
    ↓
[各タブに状態別URLを表示]
    - Inbox: 最大50件制限
    - Bookmarks: 無制限
    - Archive: 無制限

[Share Extensionからの追加]
    ↓
repository.canAddToInbox()チェック
    ↓ true → 追加成功
    ↓ false → ShareError.inboxFull
    ↓
[Inboxに追加 or エラー表示]
```

---

## 議論の記録

### 設計時の懸念と解決

**懸念1**: 「単一モデルだと今後の機能追加が苦しくならないか？」

**回答**:
- 現在の要件では各状態で同じデータ構造（url, title, createdAt）
- 主目的は「ためっぱなし防止」のための状態区別
- 将来状態固有プロパティが必要になった場合でも対応可能
  - オプション1: Bookmarkに追加（使わない状態ではnil）
  - オプション2: その時点で別モデルに分離するマイグレーション

**懸念2**: 「タブ分離表示で単一モデルは使いにくくないか？」

**回答**:
- `@Query(filter:)`で状態フィルターが可能
- View側で状態別の表示ロジックを実装可能
- 各タブで異なるソート順も設定可能
- 単一モデルでもUI分離は問題なく実現できる

### ユーザーの設計決定

| 項目 | 選択肢 | 決定 | 理由 |
|------|--------|------|------|
| 既存データの扱い | inbox / bookmark | **inbox** | 新機能として分類を促す |
| inbox上限 | 50 / 100 / 200 | **50件** | こまめな整理を促進 |
| 上限到達時の動作 | 拒否 / 自動アーカイブ | **拒否** | シンプルでユーザーの意思を尊重 |

---

## アーキテクチャの利点

### 単一モデル方式のメリット
- 状態移動がプロパティ更新のみで完結（データコピー不要）
- CloudKit同期の安定性（削除＋作成ではなく更新のみ）
- クエリのシンプルさ（単一テーブル）
- マイグレーションの容易さ（軽量マイグレーション）

### 拡張性の確保
- 将来的に別モデルへの分離が必要になっても移行可能
- 状態固有プロパティはextensionで追加可能
- View層で状態別の振る舞いを実装可能

### ためっぱなし防止機能の実現
- inbox50件制限で整理を強制
- 状態移動の心理的ハードルを下げる（プロパティ変更のみ）
- 3つの分類先で整理の選択肢を提供

---

## 実装予定日: 2026-01-17
