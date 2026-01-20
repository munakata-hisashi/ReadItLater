# 006: URL状態管理 - スキーママイグレーション

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

### 段階的実装計画

この機能は以下の4段階で実装します：

- **006** (本ドキュメント): スキーママイグレーション（基盤のみ）
- **007**: Share Extension対応（Inbox追加機能）
- **008**: Repository層完成（状態移動ロジック）
- **009**: UI実装（タブとリスト表示）

**本ドキュメント（006）の範囲**: AppV3Schemaの定義とマイグレーション実装により、アプリが正常に起動する状態を作ります。

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
        var addedInboxAt: Date = Date.now  // Inboxに追加された日時
        var url: String?
        var title: String?

        // Inbox固有のプロパティ
        var lastRemindedAt: Date?
        var isRead: Bool = false

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
        }
    }

    /// Bookmark: 定期的に見たいURL
    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now  // 重要: デフォルト値必須（軽量マイグレーション）
        var bookmarkedAt: Date = Date.now  // Bookmarkに移動した日時
        var url: String?
        var title: String?

        // Bookmark固有のプロパティ
        var lastViewedAt: Date?
        var viewCount: Int = 0

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date, bookmarkedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.bookmarkedAt = bookmarkedAt
        }
    }

    /// Archive: 読み終わったURL
    @Model
    final class Archive {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now  // 重要: デフォルト値必須（軽量マイグレーション）
        var archivedAt: Date = Date.now  // Archiveに移動した日時
        var url: String?
        var title: String?

        // Archive固有のプロパティ
        var fullTextContent: String?
        var readingNotes: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date, archivedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.archivedAt = archivedAt
        }
    }
}
```

### マイグレーション方式

**軽量マイグレーション（Lightweight Migration）**を採用：

プロパティ名の変更と新規プロパティの追加のみなので、SwiftDataの自動マイグレーション機能を使用します。

```swift
struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self,
        AppV3Schema.self  // 追加
    ]

    static let stages: [MigrationStage] = []  // 空配列 = 軽量マイグレーション
}
```

### 既存データの扱い

**設計決定**:
- 既存の全ブックマークは**Bookmark**として保持
- 理由: まだ開発中で実ユーザーがいないため、テストデータとして扱う
- 軽量マイグレーションでSwiftDataが自動的に変換

**日時の扱い**:
- `createdAt`プロパティは削除される
- `addedInboxAt`と`bookmarkedAt`は新規追加され、マイグレーション時刻で初期化される
- テストデータなので日時情報の保持は不要

**重要な注意点**:
- V2のBookmarkモデルは削除され、V3の新しいBookmarkモデルに置き換わる
- CloudKit上では既存のBookmarkレコードが更新される形で同期される
- 新規追加されるURLは全てInboxに入る（既存データのみBookmark）

---

## 実装手順

### 1. Migration/VersionedSchema.swift

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
        var addedInboxAt: Date = Date.now
        var url: String?
        var title: String?
        var lastRemindedAt: Date?
        var isRead: Bool = false

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
        }
    }

    @Model
    final class Bookmark {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now  // 重要: デフォルト値必須（軽量マイグレーション）
        var bookmarkedAt: Date = Date.now
        var url: String?
        var title: String?
        var lastViewedAt: Date?
        var viewCount: Int = 0

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date, bookmarkedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.bookmarkedAt = bookmarkedAt
        }
    }

    @Model
    final class Archive {
        var id: UUID = UUID()
        var addedInboxAt: Date = Date.now  // 重要: デフォルト値必須（軽量マイグレーション）
        var archivedAt: Date = Date.now
        var url: String?
        var title: String?
        var fullTextContent: String?
        var readingNotes: String?

        init(id: UUID = UUID(), url: String, title: String, addedInboxAt: Date, archivedAt: Date = Date.now) {
            self.id = id
            self.url = url
            self.title = title
            self.addedInboxAt = addedInboxAt
            self.archivedAt = archivedAt
        }
    }
}
```

**技術ポイント**:
- 3つの独立したモデルで型安全性を確保
- 各モデルは状態固有のプロパティを持つ
- シンプルな設計で理解しやすい

### 2. Migration/MigrationPlan.swift

**変更内容**: schemas配列に`AppV3Schema`を追加（軽量マイグレーション）

```swift
struct AppMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [
        AppV1Schema.self,
        AppV2Schema.self,
        AppV3Schema.self
    ]

    static let stages: [MigrationStage] = []  // 空配列 = 軽量マイグレーション
}
```

**技術ポイント**:
- 空のstages配列により、SwiftDataが自動的に軽量マイグレーションを実行
- プロパティ名の変更（`createdAt` → `addedInboxAt`）と新規プロパティ追加を自動処理
- カスタムロジック不要でシンプル

### 3. Domain/ModelExtensions.swift（新規）

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
    var addedInboxAt: Date { get }
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

### 4. ModelContainerFactory.swift

**変更内容**: Schemaを3モデル（Inbox, Bookmark, Archive）に更新

```swift
enum ModelContainerFactory {
    static let appGroupIdentifier = "group.munakata-hisashi.ReadItLater"

    static func createSharedContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            Inbox.self,
            Bookmark.self,
            Archive.self
        ])
        // ... 以下同じ
    }
}
```

**技術ポイント**:
- Schemaに3つのモデルを登録
- migrationPlanは既に指定されているため変更不要

### 5. Infrastructure/BookmarkRepository.swift

**変更内容**: V3 Bookmarkのイニシャライザに`addedInboxAt`引数を追加

```swift
func add(_ bookmarkData: BookmarkData) {
    let newBookmark = Bookmark(
        url: bookmarkData.url,
        title: bookmarkData.title,
        addedInboxAt: Date.now  // 新規追加
    )
    modelContext.insert(newBookmark)
}
```

**技術ポイント**:
- 新規ブックマーク追加時は現在時刻を`addedInboxAt`に設定

### 6. ShareExtension/ShareViewController.swift

**変更内容**: V3 Bookmarkのイニシャライザに`addedInboxAt`引数を追加

```swift
private func saveBookmark(url: String, title: String?) async throws {
    // ...
    let bookmark = Bookmark(
        url: bookmarkData.url,
        title: bookmarkData.title,
        addedInboxAt: Date.now  // 新規追加
    )
    context.insert(bookmark)
    try context.save()
}
```

**技術ポイント**:
- Share Extension経由でのブックマーク追加も同様に対応

### 7. View/ContentView.swift

**変更内容**: Previewを3モデル対応に更新

```swift
#Preview {
    let schema = Schema([
        Inbox.self,
        Bookmark.self,
        Archive.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let modelContainer = try! ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: modelConfiguration)
    ContentView()
        .modelContainer(modelContainer)
}
```

### 8. View/BookmarkView.swift

**変更内容**: Previewを3モデル対応に更新

```swift
#Preview {
    let schema = Schema([
        Inbox.self,
        Bookmark.self,
        Archive.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: config)
    let example = Bookmark(
        url: "https://example.com",
        title: "Example",
        addedInboxAt: Date.now  // 新規追加
    )
    BookmarkView(bookmark: example)
        .modelContainer(container)
}
```

### 9. ReadItLaterTests/Infrastructure/BookmarkRepositoryTests.swift

**変更内容**: 全てのBookmark直接生成箇所（5箇所）で`addedInboxAt`引数を追加

```swift
// 変更前
let bookmark = Bookmark(url: "https://example.com", title: "Example")

// 変更後
let bookmark = Bookmark(url: "https://example.com", title: "Example", addedInboxAt: Date.now)
```

**該当箇所**:
- 行64: `ブックマーク削除_単一削除成功`テスト
- 行91-93: `ブックマーク削除_複数削除成功`テスト（3箇所）
- 行121: `ブックマーク削除_空配列を削除`テスト
- 行141-142: `ブックマーク削除_全件削除`テスト（2箇所）

---

## 修正対象ファイル一覧

### 変更ファイル（8ファイル）

| ファイル | 変更内容 |
|---------|---------|
| `Migration/VersionedSchema.swift` | AppV3Schemaに3つのモデル（Inbox, Bookmark, Archive）を追加 |
| `Migration/MigrationPlan.swift` | AppV3Schemaを追加、軽量マイグレーション（stages = []） |
| `ModelContainerFactory.swift` | Schemaを3モデル（Inbox, Bookmark, Archive）に更新 |
| `Infrastructure/BookmarkRepository.swift` | V3 Bookmarkのイニシャライザ（`addedInboxAt`引数追加）に対応 |
| `View/ContentView.swift` | Previewを3モデル対応に更新 |
| `View/BookmarkView.swift` | Previewを3モデル対応に更新 |
| `ShareExtension/ShareViewController.swift` | V3 Bookmarkのイニシャライザに対応 |
| `ReadItLaterTests/Infrastructure/BookmarkRepositoryTests.swift` | V3 Bookmarkのイニシャライザに対応（5箇所） |

**注意**: 当初の計画では4ファイルの変更を想定していましたが、V3 Bookmarkのイニシャライザ変更により、アプリが正常にビルド・起動できる状態を維持するため、影響範囲を拡大しました。

### 新規ファイル（1ファイル）

| ファイル | 目的 |
|---------|------|
| `Domain/ModelExtensions.swift` | 3モデルのtype aliasと共通プロトコル定義 |

### 削除ファイル（1ファイル）

| ファイル | 理由 |
|---------|------|
| `Domain/BookmarkExtensions.swift` | ModelExtensions.swiftに統合 |

---

## 検証方法

### 1. ビルド確認
```bash
mise run build
# または
xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' build
```

**期待結果**: コンパイルエラーなし

### 2. ユニットテスト実行
```bash
mise run unit
# または
xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' \
  test -only-testing:ReadItLaterTests
```

**期待結果**: 全テストパス

### 3. アプリ起動確認

1. シミュレータでアプリを起動
2. アプリがクラッシュせずに起動することを確認
3. 既存のブックマークが表示されることを確認（日時は初期化されている）

### 4. 新規ブックマーク追加確認

1. +ボタンからブックマーク追加画面を開く
2. URLとタイトルを入力して保存
3. リストに追加されることを確認

### 5. Preview確認

Xcode上で以下のPreviewが正常に表示されることを確認:
- ContentView Preview
- BookmarkView Preview
- AddBookmarkSheet Preview

### 6. マイグレーション確認（オプション）

- V3スキーマが正しく適用されているか確認
- 軽量マイグレーションが正常に実行されたか確認
- CloudKit Dashboardで既存レコードが更新されているか確認（オプション）

---

## 技術的考慮事項

### 軽量マイグレーション

**軽量マイグレーションの条件**:
- SwiftDataが自動的にスキーマ変更を処理
- プロパティ名変更と新規プロパティ追加を自動で実行
- カスタムロジック不要でシンプル
- 既存データはBookmarkとして保持、日時は初期化

**軽量マイグレーションが可能な変更**:
- プロパティの追加（デフォルト値が必要）
- プロパティの削除
- プロパティ名の変更（特定の条件下）
- 型の変換（互換性のある型のみ）

### CloudKit同期

**同期の仕組み**:
- 各モデル（Inbox, Bookmark, Archive）は独立したCloudKitレコードタイプとして同期
- マイグレーション時は既存BookmarkレコードがV3 Bookmarkとして更新される
- `addedInboxAt`を引き継ぐことで元の追加日時を保持（ただし今回は初期化）

**競合リスクと対策**:
- **競合発生条件**: オフライン時に同じアイテムを別デバイスで編集＋状態移動
- **発生確率**: 基本的にオンライン使用のため極めて稀（月に1回未満）
- **影響範囲**: 最悪の場合、1件のURLの編集内容が消失
- **許容理由**: URLは外部に存在するため再取得可能、個人用途で影響は限定的

**シンプルな設計の選択**:
- 論理削除やトランザクションテーブルは採用しない
- 過剰な対策よりも実装のシンプルさを優先
- 将来問題が顕在化した場合に対策を検討

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

### マイグレーション方式の決定

**カスタムマイグレーション vs 軽量マイグレーション**:
- 当初はカスタムマイグレーションで既存データの日時を保持する計画
- テストデータのみなので日時保持は不要と判断
- よりシンプルな軽量マイグレーションを採用

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

**軽量マイグレーション**:
- カスタムロジック不要
- SwiftDataの自動処理に任せる
- コード量が少ない
- メンテナンスが容易

---

## 次のステップ

006の実装完了後、以下の順序で機能を追加していきます：

1. **007: Share Extension対応** - Inboxへの追加機能を実装し、実データで動作確認
2. **008: Repository層完成** - 状態移動ロジックを実装し、ユニットテストで検証
3. **009: UI実装** - 3タブUIとスワイプアクションを実装し、エンドユーザーが操作可能に

---

## 実装予定日

2026-01-18（006のみ）
