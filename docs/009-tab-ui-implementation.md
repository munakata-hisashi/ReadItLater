# 009: タブバーUI実装（Inbox / Bookmarks / Archive）

## 背景と目的

008でRepository層の状態移動ロジックが完成し、プログラムからInbox/Bookmark/Archive間のデータ移動が可能になりました。次のステップとして、**3つのタブを持つUIを実装**し、エンドユーザーが直感的に操作できる環境を整えます。

### このステップの目的

- タブバーを導入し、Inbox/Bookmarks/Archiveの3画面を提供
- 各タブでリスト表示とスワイプアクションによる状態移動を実装
- 共通コンポーネントを活用した保守性の高いUI設計

### 段階的実装の位置づけ

- **006**: スキーママイグレーション（基盤のみ）✅
- **007**: Share Extension対応（Inbox追加機能）✅
- **008**: Repository層完成（状態移動ロジック）✅
- **009** (本ドキュメント): タブバーUI実装

**009のゴール**: ユーザーがタブを切り替えながら、スワイプ操作でURL項目を管理できる状態にすること

---

## 前提条件

- 008が完了していること
  - InboxRepository、BookmarkRepository、ArchiveRepositoryが実装されている
  - 状態移動メソッド（moveToBookmark、moveToArchiveなど）が実装されている

- URLItemプロトコルが定義されていること
  - Inbox、Bookmark、Archiveの3モデルがURLItemプロトコルに準拠している
  - `safeTitle`、`maybeURL`などの共通extensionが実装されている

---

## 実装内容

### 1. 共通コンポーネントの作成

#### 1.1 URLItemRow.swift（新規作成）

リストアイテムの共通表示コンポーネント。URLItemプロトコルに準拠したモデルを受け取り、タイトルとURLを表示します。

```swift
//
//  URLItemRow.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI

/// リストアイテムの共通表示コンポーネント
///
/// URLItemプロトコルに準拠したモデルの共通表示ビュー
struct URLItemRow: View {
    let item: any URLItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.safeTitle)
                .font(.headline)
                .lineLimit(2)

            if let urlString = item.url {
                Text(urlString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
```

**技術ポイント**:
- `any URLItem`を受け取ることで、Inbox/Bookmark/Archiveのいずれでも使用可能
- プロトコル指向設計により、共通表示ロジックを一元化

#### 1.2 URLItemDetailView.swift（新規作成）

URLItemの詳細画面。WebViewを使用してURLの内容を表示します。

```swift
//
//  URLItemDetailView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

/// URLItemプロトコルを活用した汎用詳細画面
///
/// Inbox、Bookmark、Archiveの詳細表示に使用する共通ビュー
struct URLItemDetailView: View {
    let item: any URLItem

    var body: some View {
        VStack {
            if let url = item.maybeURL {
                WebView(url: url)
            } else {
                VStack {
                    Text(item.safeTitle)
                    Text("No URL")
                }
            }
        }
        .navigationTitle(item.safeTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

**技術ポイント**:
- 既存のBookmarkView.swiftの機能を汎用化
- URLItemプロトコルを活用し、3つのモデルすべてで使用可能

### 2. 各タブのリストビュー作成

#### 2.1 InboxListView.swift（新規作成）

Inboxタブのリスト表示。「+」ボタンでURL追加、スワイプアクションで状態移動を実現します。

```swift
//
//  InboxListView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

struct InboxListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Inbox.addedInboxAt, order: .reverse) private var inboxItems: [Inbox]
    @State private var showingAddSheet = false

    /// Repository（computed propertyとして生成）
    private var repository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    var body: some View {
        List {
            ForEach(inboxItems) { inbox in
                NavigationLink(value: inbox) {
                    URLItemRow(item: inbox)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        moveToBookmark(inbox)
                    } label: {
                        Label("Bookmark", systemImage: "bookmark")
                    }
                    .tint(.blue)

                    Button {
                        moveToArchive(inbox)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteInbox(inbox)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Inbox")
        .navigationDestination(for: Inbox.self) { inbox in
            URLItemDetailView(item: inbox)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBookmarkSheet(
                onSave: { bookmarkData in
                    addToInbox(from: bookmarkData)
                    showingAddSheet = false
                },
                onCancel: {
                    showingAddSheet = false
                }
            )
        }
    }

    private func addToInbox(from bookmarkData: BookmarkData) {
        withAnimation {
            do {
                try repository.add(url: bookmarkData.url, title: bookmarkData.title)
            } catch {
                // TODO: エラーハンドリング（アラート表示など）
                print("Failed to add to Inbox: \(error)")
            }
        }
    }

    private func moveToBookmark(_ inbox: Inbox) {
        withAnimation {
            do {
                try repository.moveToBookmark(inbox)
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func moveToArchive(_ inbox: Inbox) {
        withAnimation {
            do {
                try repository.moveToArchive(inbox)
            } catch {
                print("Failed to move to Archive: \(error)")
            }
        }
    }

    private func deleteInbox(_ inbox: Inbox) {
        withAnimation {
            repository.delete(inbox)
        }
    }
}
```

**技術ポイント**:
- `@Query(sort: \Inbox.addedInboxAt, order: .reverse)` - 新しい順にソート
- スワイプアクション：左から右（Bookmark/Archive）、右から左（削除）
- Repositoryパターンで状態移動を実装

#### 2.2 BookmarkListView.swift（新規作成）

Bookmarksタブのリスト表示。既存のContentView.swiftをベースに作成します。

```swift
//
//  BookmarkListView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

struct BookmarkListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bookmark.bookmarkedAt, order: .reverse) private var bookmarks: [Bookmark]
    @State private var showingAddSheet = false

    /// Repository（computed propertyとして生成）
    private var repository: BookmarkRepositoryProtocol {
        BookmarkRepository(modelContext: modelContext)
    }

    var body: some View {
        List {
            ForEach(bookmarks) { bookmark in
                NavigationLink(value: bookmark) {
                    URLItemRow(item: bookmark)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        moveToArchive(bookmark)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteBookmark(bookmark)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Bookmarks")
        .navigationDestination(for: Bookmark.self) { bookmark in
            URLItemDetailView(item: bookmark)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Bookmark", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBookmarkSheet(
                onSave: { bookmarkData in
                    addBookmark(from: bookmarkData)
                    showingAddSheet = false
                },
                onCancel: {
                    showingAddSheet = false
                }
            )
        }
    }

    private func addBookmark(from bookmarkData: BookmarkData) {
        withAnimation {
            repository.add(bookmarkData)
        }
    }

    private func moveToArchive(_ bookmark: Bookmark) {
        withAnimation {
            do {
                try repository.moveToArchive(bookmark)
            } catch {
                print("Failed to move to Archive: \(error)")
            }
        }
    }

    private func deleteBookmark(_ bookmark: Bookmark) {
        withAnimation {
            repository.delete(bookmark)
        }
    }
}
```

**技術ポイント**:
- `@Query(sort: \Bookmark.bookmarkedAt, order: .reverse)` - ブックマーク日時の新しい順
- NavigationSplitView → NavigationStackに変更（タブ内表示のため）
- スワイプアクション：左から右（Archive）、右から左（削除）

#### 2.3 ArchiveListView.swift（新規作成）

Archiveタブのリスト表示。Archiveから再度Bookmarkへ戻す機能を提供します。

```swift
//
//  ArchiveListView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI
import SwiftData

struct ArchiveListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Archive.archivedAt, order: .reverse) private var archiveItems: [Archive]

    /// Repository（computed propertyとして生成）
    private var repository: ArchiveRepositoryProtocol {
        ArchiveRepository(modelContext: modelContext)
    }

    var body: some View {
        List {
            ForEach(archiveItems) { archive in
                NavigationLink(value: archive) {
                    URLItemRow(item: archive)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        moveToBookmark(archive)
                    } label: {
                        Label("Bookmark", systemImage: "bookmark")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteArchive(archive)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Archive")
        .navigationDestination(for: Archive.self) { archive in
            URLItemDetailView(item: archive)
        }
    }

    private func moveToBookmark(_ archive: Archive) {
        withAnimation {
            do {
                try repository.moveToBookmark(archive)
            } catch {
                print("Failed to move to Bookmark: \(error)")
            }
        }
    }

    private func deleteArchive(_ archive: Archive) {
        withAnimation {
            repository.delete(archive)
        }
    }
}
```

**技術ポイント**:
- `@Query(sort: \Archive.archivedAt, order: .reverse)` - アーカイブ日時の新しい順
- 「+」ボタンなし（ArchiveはInboxまたはBookmarkから移動してくるのみ）
- スワイプアクション：左から右（Bookmark）、右から左（削除）

### 3. MainTabView.swift（新規作成）

3つのタブを統合するメインビュー。アプリのエントリポイントになります。

```swift
//
//  MainTabView.swift
//  ReadItLater
//
//  Created by Claude Code on 2026/01/23.
//

import SwiftUI

/// アプリのメインタブビュー
///
/// Inbox、Bookmarks、Archiveの3つのタブを提供
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                InboxListView()
            }
            .tabItem {
                Label("Inbox", systemImage: "tray")
            }

            NavigationStack {
                BookmarkListView()
            }
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }

            NavigationStack {
                ArchiveListView()
            }
            .tabItem {
                Label("Archive", systemImage: "archivebox")
            }
        }
    }
}
```

**技術ポイント**:
- 各タブを独立したNavigationStackでラップ
- SF Symbolsを使用したタブアイコン（tray、bookmark、archivebox）
- タブの順序：Inbox → Bookmarks → Archive（ワークフローに沿った配置）

### 4. エントリポイントの更新

#### ReadItLaterApp.swift（修正）

アプリのエントリポイントを`ContentView`から`MainTabView`に変更します。

```swift
var body: some Scene {
    WindowGroup {
        MainTabView()  // ContentView() から変更
    }
    .modelContainer(sharedModelContainer)
}
```

### 5. 既存ファイルの削除

以下のファイルは新しいコンポーネントに置き換えられるため削除します：

- **View/ContentView.swift** - BookmarkListViewに置き換え
- **View/BookmarkView.swift** - URLItemDetailViewに置き換え

---

## 実装手順

### 1. 共通コンポーネント作成

1. `ReadItLater/View/URLItemRow.swift` を新規作成
2. `ReadItLater/View/URLItemDetailView.swift` を新規作成

### 2. 各タブのリストビュー作成

1. `ReadItLater/View/InboxListView.swift` を新規作成
2. `ReadItLater/View/BookmarkListView.swift` を新規作成
3. `ReadItLater/View/ArchiveListView.swift` を新規作成

### 3. MainTabView作成

1. `ReadItLater/View/MainTabView.swift` を新規作成

### 4. エントリポイント更新

1. `ReadItLater/ReadItLaterApp.swift` を修正
   - 23行目: `ContentView()` → `MainTabView()`

### 5. 既存ファイル削除

1. `ReadItLater/View/ContentView.swift` を削除
2. `ReadItLater/View/BookmarkView.swift` を削除

---

## 修正対象ファイル一覧

### 新規作成ファイル

| ファイル | 目的 |
|---------|------|
| `View/URLItemRow.swift` | リストアイテムの共通表示コンポーネント |
| `View/URLItemDetailView.swift` | URLItem用の汎用詳細画面 |
| `View/InboxListView.swift` | Inboxタブのリスト表示 |
| `View/BookmarkListView.swift` | Bookmarksタブのリスト表示 |
| `View/ArchiveListView.swift` | Archiveタブのリスト表示 |
| `View/MainTabView.swift` | 3つのタブを統合するメインビュー |

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `ReadItLaterApp.swift` | エントリポイントを`MainTabView()`に変更（23行目） |

### 削除ファイル

| ファイル | 理由 |
|---------|------|
| `View/ContentView.swift` | BookmarkListViewに置き換え |
| `View/BookmarkView.swift` | URLItemDetailViewに置き換え |

---

## 検証方法

### ビルド確認

```bash
mise run build
```

または

```bash
xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' build
```

### 動作確認（シミュレータ）

1. **タブ切り替え**
   - 3つのタブ（Inbox / Bookmarks / Archive）が表示されることを確認
   - 各タブをタップして画面が切り替わることを確認

2. **URL追加**
   - Inboxタブで「+」ボタンをタップ
   - URLを入力して保存
   - Inboxリストに追加されることを確認

3. **スワイプアクション（Inbox）**
   - 左から右スワイプ → BookmarkまたはArchiveボタンが表示
   - Bookmarkボタンタップ → Bookmarksタブに移動
   - Archiveボタンタップ → Archiveタブに移動
   - 右から左スワイプ → 削除ボタンが表示

4. **スワイプアクション（Bookmarks）**
   - 左から右スワイプ → Archiveボタンが表示
   - 右から左スワイプ → 削除ボタンが表示

5. **スワイプアクション（Archive）**
   - 左から右スワイプ → Bookmarkボタンが表示
   - Bookmarkボタンタップ → Bookmarksタブに移動
   - 右から左スワイプ → 削除ボタンが表示

6. **詳細表示**
   - リストアイテムをタップ
   - WebViewで内容が表示されることを確認

### テスト実行

```bash
mise run test
```

または

```bash
xcodebuild -project ReadItLater.xcodeproj -scheme ReadItLater \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0.1' test
```

**期待される結果**:
- ✅ ユニットテスト: 全124件成功
- ⚠️ UIテスト: testExampleが失敗（後述の理由による）

---

## トラブルシューティング

### UIテストが失敗する（testExample）

**現象**: `ReadItLaterUITests.testExample()`が失敗する

**原因**:
- TabView導入により、初期画面が**Inboxタブ**になった
- テストは"Bookmarks"ナビゲーションバーを探しているが、Bookmarksタブに切り替えないと表示されない

**対策（テスト修正）**:

**オプション1: タブ切り替えを追加**
```swift
@MainActor
func testExample() throws {
    let app = XCUIApplication()
    app.launch()

    // Bookmarksタブをタップ
    let bookmarksTab = app.tabBars.buttons["Bookmarks"]
    bookmarksTab.tap()

    // Bookmarks画面の要素を検証
    let bookmarksNavigationBar = app.navigationBars["Bookmarks"]
    XCTAssertTrue(bookmarksNavigationBar.waitForExistence(timeout: 5))
}
```

**オプション2: Inboxタブの要素を検証**
```swift
@MainActor
func testExample() throws {
    let app = XCUIApplication()
    app.launch()

    // Inboxナビゲーションバーを確認
    let inboxNavigationBar = app.navigationBars["Inbox"]
    XCTAssertTrue(inboxNavigationBar.waitForExistence(timeout: 5))

    // 追加ボタンが存在することを確認
    let addButton = app.buttons["Add Item"]
    XCTAssertTrue(addButton.exists)
}
```

### スワイプアクションが動作しない

**原因**: Listのアイテムが存在しない

**対策**:
1. 「+」ボタンからURLを追加
2. データが存在する状態でスワイプアクションを試す

### タブが表示されない

**原因**: MainTabViewがエントリポイントに設定されていない

**対策**: `ReadItLaterApp.swift:23`で`MainTabView()`が使用されているか確認

---

## 設計判断

### NavigationSplitView → NavigationStack

**変更理由**:
- TabView内では各タブが独立したナビゲーション階層を持つ
- NavigationSplitViewはiPadのマスター・ディテール表示に適しているが、タブ内では不要
- NavigationStackのシンプルな階層構造がタブUIに適合

### プロトコル指向設計（URLItem）

**メリット**:
- URLItemRow、URLItemDetailViewが3つのモデルで共通利用可能
- DRY原則に従ったコード共有
- 新しいモデル追加時の拡張性

**実装のポイント**:
- `any URLItem`でexistential typeを使用
- プロトコル拡張で共通メソッド（`safeTitle`、`maybeURL`）を提供

### Repositoryのcomputed property化

**実装方法**:
```swift
private var repository: InboxRepositoryProtocol {
    InboxRepository(modelContext: modelContext)
}
```

**メリット**:
- 呼び出しごとに新しいインスタンスを生成
- `@Environment(\.modelContext)`の変更に自動追従
- メモリ効率が良い（使用時のみ生成）

---

## 技術的補足

### SwiftDataとSwiftUIの統合

**@Query属性**:
```swift
@Query(sort: \Inbox.addedInboxAt, order: .reverse) private var inboxItems: [Inbox]
```

- SwiftDataが自動的にデータ変更を監視
- データ更新時にViewが自動再描画
- ソート順を宣言的に指定

**状態管理**:
- `withAnimation`でスムーズなUI遷移
- Repository経由の変更がSwiftDataに反映
- CloudKit同期も自動的に動作

### スワイプアクション設計

**左右の役割分担**:
- **左から右（.leading）**: 状態移動アクション（Bookmark、Archive）
- **右から左（.trailing）**: 破壊的アクション（削除）

**allowsFullSwipe: true**:
- フルスワイプで即座にアクション実行
- ボタンタップ不要で素早い操作が可能

### タブアイコンの選定

| タブ | アイコン | 意味 |
|-----|---------|------|
| Inbox | tray | 受信トレイ（一時保管） |
| Bookmarks | bookmark | ブックマーク（お気に入り） |
| Archive | archivebox | アーカイブ（保管庫） |

---

## パフォーマンス考慮事項

### メモリ効率

- 各タブのNavigationStackは独立して管理
- 非表示タブのViewは自動的にメモリから解放される可能性
- `@Query`は必要なデータのみをフェッチ

### 描画パフォーマンス

- `URLItemRow`は軽量なコンポーネント
- `.lineLimit()`でテキストの描画を最適化
- リスト表示は遅延レンダリング（LazyVStack相当）

---

## 将来の拡張性

### 追加予定機能

1. **検索機能**
   - 各タブに検索バーを追加
   - タイトルとURLで検索

2. **フィルタリング**
   - 日付範囲でフィルタ
   - URLドメインでフィルタ

3. **一括操作**
   - 複数選択モード
   - 一括削除、一括移動

4. **エラーハンドリング**
   - アラート表示
   - エラーメッセージの多言語対応

---

## 実装完了日

2026-01-23

---

## 関連ドキュメント

- [006: URL状態管理スキーママイグレーション](./006-url-state-management-schema-migration.md)
- [007: Inbox Share Extension実装](./007-inbox-share-extension.md)
- [008: Repository層状態移動ロジック](./008-repository-state-transitions.md)
