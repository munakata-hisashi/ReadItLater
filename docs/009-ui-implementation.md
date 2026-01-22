# 009: UI実装 - 3タブとリスト表示

## 背景と目的

006〜008でスキーママイグレーション、Inbox追加、状態移動ロジックを実装しました。最後のステップとして、**エンドユーザーがUIから操作できる**3タブインターフェースを実装します。

### このステップの目的

- 3つのタブ（Inbox、Bookmark、Archive）を実装
- 各タブでリスト表示
- スワイプアクションで状態移動
- Inbox上限表示（XX/5、開発用。将来的には50件に変更予定）

### 段階的実装の位置づけ

- **006**: スキーママイグレーション（基盤のみ）✅
- **007**: Share Extension対応（Inbox追加機能）✅
- **008**: Repository層完成（状態移動ロジック）✅
- **009** (本ドキュメント): UI実装（タブとリスト表示）**← 未実装**

**009のゴール**: ユーザーがアプリから3つの状態を表示・操作できる状態にすること

---

## 前提条件

- 006が完了していること
  - AppV3Schemaが定義されている
  - 軽量マイグレーションが実装されている

- 007が完了していること
  - InboxConfigurationが定義されている
  - InboxRepositoryが実装されている（Inbox追加）
  - Share Extensionからデータ追加可能

- 008が完了していること
  - 個別Repository（InboxRepository、BookmarkRepository、ArchiveRepository）が実装されている
  - 状態移動メソッドが実装されている
    - InboxRepository: `moveToBookmark(_:)`, `moveToArchive(_:)`
    - BookmarkRepository: `moveToArchive(_:)`
    - ArchiveRepository: `moveToBookmark(_:)`
  - ユニットテストが通っている

---

## 実装内容

### 1. ContentView - 3タブレイアウト

メインのContentViewを3タブ構成に変更します。

```swift
//
//  ContentView.swift
//  ReadItLater
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // 各モデルを独立してクエリ
    @Query private var inboxItems: [Inbox]
    @Query private var bookmarkItems: [Bookmark]
    @Query private var archiveItems: [Archive]

    private var inboxRepository: InboxRepositoryProtocol {
        InboxRepository(modelContext: modelContext)
    }

    private var bookmarkRepository: BookmarkRepositoryProtocol {
        BookmarkRepository(modelContext: modelContext)
    }

    private var archiveRepository: ArchiveRepositoryProtocol {
        ArchiveRepository(modelContext: modelContext)
    }

    var body: some View {
        TabView {
            InboxListView(
                items: inboxItems,
                repository: inboxRepository
            )
            .tabItem {
                Label("Inbox", systemImage: "tray")
            }

            BookmarkListView(
                items: bookmarkItems,
                repository: bookmarkRepository
            )
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark")
            }

            ArchiveListView(
                items: archiveItems,
                repository: archiveRepository
            )
            .tabItem {
                Label("Archive", systemImage: "archivebox")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Inbox.self, Bookmark.self, Archive.self], inMemory: true)
}
```

**技術ポイント**:
- `@Query`で各モデルを独立取得
- 個別Repository（InboxRepository、BookmarkRepository、ArchiveRepository）を使って状態移動を実行
- TabViewで3つのタブを実装

### 2. InboxListView

Inbox専用のリスト表示ビューを実装します。

```swift
//
//  InboxListView.swift
//  ReadItLater
//

import SwiftUI
import SwiftData

struct InboxListView: View {
    let items: [Inbox]
    let repository: InboxRepositoryProtocol
    @State private var showingAddSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { inbox in
                    InboxListRow(inbox: inbox)
                        .swipeActions(edge: .leading) {
                            Button {
                                try? repository.moveToBookmark(inbox)
                            } label: {
                                Label("Bookmark", systemImage: "bookmark")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                try? repository.moveToArchive(inbox)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.green)

                            Button(role: .destructive) {
                                repository.delete(inbox)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Inbox (\(items.count)/\(InboxConfiguration.maxItems))")
            .toolbar {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddBookmarkSheet(repository: repository)
            }
        }
    }
}

struct InboxListRow: View {
    let inbox: Inbox

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(inbox.safeTitle)
                .font(.headline)

            if let url = inbox.url {
                Text(url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(inbox.addedInboxAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Inbox.self, Bookmark.self, Archive.self,
        configurations: config
    )
    let context = ModelContext(container)

    let inbox1 = Inbox(url: "https://example.com", title: "Example Site")
    let inbox2 = Inbox(url: "https://swift.org", title: "Swift.org")
    context.insert(inbox1)
    context.insert(inbox2)

    let repository = InboxRepository(modelContext: context)

    return InboxListView(
        items: [inbox1, inbox2],
        repository: repository
    )
}
```

**技術ポイント**:
- スワイプアクション（左: Bookmark、右: Archive/Delete）
- Inbox上限表示（XX/5、開発用。将来的には50件に変更予定）
- 相対時間表示（"2 hours ago"など）

### 3. BookmarkListView

Bookmark専用のリスト表示ビューを実装します。

```swift
//
//  BookmarkListView.swift
//  ReadItLater
//

import SwiftUI
import SwiftData

struct BookmarkListView: View {
    let items: [Bookmark]
    let repository: BookmarkRepositoryProtocol

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { bookmark in
                    BookmarkListRow(bookmark: bookmark)
                        .swipeActions(edge: .trailing) {
                            Button {
                                try? repository.moveToArchive(bookmark)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.green)

                            Button(role: .destructive) {
                                repository.delete(bookmark)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Bookmarks (\(items.count))")
        }
    }
}

struct BookmarkListRow: View {
    let bookmark: Bookmark

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bookmark.safeTitle)
                .font(.headline)

            if let url = bookmark.url {
                Text(url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {
                Text("Added: \(bookmark.addedInboxAt, style: .relative)")
                Spacer()
                Text("Bookmarked: \(bookmark.bookmarkedAt, style: .relative)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Bookmark.self, Archive.self,
        configurations: config
    )
    let context = ModelContext(container)

    let bookmark1 = Bookmark(
        url: "https://example.com",
        title: "Example Site",
        addedInboxAt: Date().addingTimeInterval(-86400),
        bookmarkedAt: Date()
    )
    context.insert(bookmark1)

    let repository = BookmarkRepository(modelContext: context)

    return BookmarkListView(
        items: [bookmark1],
        repository: repository
    )
}
```

**技術ポイント**:
- スワイプアクション（右: Archive/Delete）
- Bookmarked日時も表示

### 4. ArchiveListView

Archive専用のリスト表示ビューを実装します。

```swift
//
//  ArchiveListView.swift
//  ReadItLater
//

import SwiftUI
import SwiftData

struct ArchiveListView: View {
    let items: [Archive]
    let repository: ArchiveRepositoryProtocol

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { archive in
                    ArchiveListRow(archive: archive)
                        .swipeActions(edge: .leading) {
                            Button {
                                try? repository.moveToBookmark(archive)
                            } label: {
                                Label("Bookmark", systemImage: "bookmark")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                repository.delete(archive)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Archive (\(items.count))")
        }
    }
}

struct ArchiveListRow: View {
    let archive: Archive

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(archive.safeTitle)
                .font(.headline)

            if let url = archive.url {
                Text(url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {
                Text("Added: \(archive.addedInboxAt, style: .relative)")
                Spacer()
                Text("Archived: \(archive.archivedAt, style: .relative)")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Archive.self, Bookmark.self,
        configurations: config
    )
    let context = ModelContext(container)

    let archive1 = Archive(
        url: "https://example.com",
        title: "Example Site",
        addedInboxAt: Date().addingTimeInterval(-172800),
        archivedAt: Date()
    )
    context.insert(archive1)

    let repository = ArchiveRepository(modelContext: context)

    return ArchiveListView(
        items: [archive1],
        repository: repository
    )
}
```

**技術ポイント**:
- スワイプアクション（左: Bookmark、右: Delete）
- Archived日時も表示

### 5. AddBookmarkSheet

アプリ内からInboxに追加するシートを実装します。

```swift
//
//  AddBookmarkSheet.swift
//  ReadItLater
//

import SwiftUI

struct AddBookmarkSheet: View {
    @Environment(\.dismiss) private var dismiss
    let repository: InboxRepositoryProtocol

    @State private var urlString = ""
    @State private var title = ""
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section("URL") {
                    TextField("https://example.com", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Title") {
                    TextField("Optional title", text: $title)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add to Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addBookmark()
                    }
                    .disabled(urlString.isEmpty)
                }
            }
        }
    }

    private func addBookmark() {
        do {
            try repository.addToInbox(
                url: urlString,
                title: title.isEmpty ? urlString : title
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Inbox.self,
        configurations: config
    )
    let context = ModelContext(container)
    let repository = InboxRepository(modelContext: context)

    return AddBookmarkSheet(repository: repository)
}
```

**技術ポイント**:
- フォーム形式でURL入力
- エラーメッセージ表示
- Repository経由で追加

---

## 実装手順

### 1. ContentView.swiftを更新

既存のContentViewを3タブ構成に変更します。

### 2. InboxListView.swiftを作成

**ファイルパス**: `ReadItLater/View/InboxListView.swift`

### 3. BookmarkListView.swiftを作成

**ファイルパス**: `ReadItLater/View/BookmarkListView.swift`

### 4. ArchiveListView.swiftを作成

**ファイルパス**: `ReadItLater/View/ArchiveListView.swift`

### 5. AddBookmarkSheet.swiftを作成

**ファイルパス**: `ReadItLater/View/AddBookmarkSheet.swift`

---

## 修正対象ファイル一覧

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `View/ContentView.swift` | 3タブレイアウトに変更 |

### 新規ファイル

| ファイル | 目的 |
|---------|------|
| `View/InboxListView.swift` | Inboxタブのリスト表示 |
| `View/BookmarkListView.swift` | Bookmarkタブのリスト表示 |
| `View/ArchiveListView.swift` | Archiveタブのリスト表示 |
| `View/AddBookmarkSheet.swift` | アプリ内からInbox追加するシート |

**注**: 既存の`BookmarkView.swift`（詳細表示用）と`AddBookmarkViewModel.swift`（メタデータ取得機能）は保持します。将来の機能拡張で使用予定です。

---

## 検証方法

### ビルド確認
```bash
mise run build
```

### UI動作確認

#### 1. 初回起動

1. アプリをビルド＆実行
2. 3つのタブ（Inbox、Bookmarks、Archive）が表示されることを確認
3. 既存データがBookmarksタブに表示されることを確認

#### 2. Inbox追加

**方法A: Share Extensionから**
1. Safariで任意のWebページを開く
2. 共有ボタンをタップ
3. 「ReadItLater」を選択
4. Inboxタブに追加されることを確認

**方法B: アプリ内から**
1. Inboxタブの「+」ボタンをタップ
2. URLとタイトルを入力
3. 「Add」をタップ
4. Inboxタブに追加されることを確認

#### 3. 状態移動

**Inbox → Bookmark**:
1. Inboxのアイテムを左スワイプ
2. 「Bookmark」をタップ
3. Bookmarksタブに移動することを確認

**Inbox → Archive**:
1. Inboxのアイテムを右スワイプ
2. 「Archive」をタップ
3. Archiveタブに移動することを確認

**Bookmark → Archive**:
1. Bookmarksのアイテムを右スワイプ
2. 「Archive」をタップ
3. Archiveタブに移動することを確認

**Archive → Bookmark**:
1. Archiveのアイテムを左スワイプ
2. 「Bookmark」をタップ
3. Bookmarksタブに移動することを確認

#### 4. 削除

1. 任意のアイテムを右スワイプ
2. 「Delete」をタップ
3. アイテムが削除されることを確認

#### 5. Inbox上限

1. Share Extensionから5件のURLを追加
2. Inboxタブのタイトルが「Inbox (5/5)」と表示されることを確認
3. 6件目を追加しようとする
4. 「Inboxが上限に達しています」エラーが表示されることを確認

**注**: 現在の開発用設定では上限は5件です。将来的には50件に変更予定です。

---

## トラブルシューティング

### スワイプアクションが動作しない

**原因**: Repositoryの参照が正しく渡されていない

**対策**: ContentViewでRepositoryを作成し、各Viewに渡す

### タブ切り替えでデータが更新されない

**原因**: `@Query`が再実行されていない

**対策**: SwiftDataは自動的に更新されるため、通常は問題なし。もし更新されない場合は、`@Environment(\.modelContext)`を確認

### プレビューが動作しない

**原因**: ModelContainerの初期化に失敗

**対策**: プレビューでは`inMemory: true`を使用し、必要なモデルを全て指定

---

## UI/UXの今後の改善案

### 短期改善

- リスト項目をタップしてWebViewで表示
- 検索機能（タイトル、URL）
- ソート機能（日時、タイトル）
- Inboxの未読/既読フラグ表示

### 中期改善

- Bookmarkのランダムピックアップ機能
- Inboxのリマインダー機能
- Archiveの全文検索
- Inbox上限警告（80%到達時）

### 長期改善

- iPadマルチカラム対応
- macOS対応
- ウィジェット対応
- Handoff対応

---

## 完成

009の実装完了により、以下の機能が全て動作する状態になります：

✅ **006**: スキーママイグレーション（別モデル方式）
✅ **007**: Share Extension対応（Inboxへの追加）
✅ **008**: Repository層完成（状態移動ロジック）
✅ **009**: UI実装（3タブとスワイプアクション）

**エンドユーザーができること**:
- SafariなどからURLをInboxに追加
- 3つのタブで状態を表示
- スワイプアクションで状態を移動
- Inbox上限（5件、開発用）の管理
