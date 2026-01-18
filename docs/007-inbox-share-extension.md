# 007: Inbox追加機能 - Share Extension対応

## 背景と目的

006でスキーママイグレーションを完了し、アプリが正常に起動する状態になりました。次のステップとして、**実際にInboxにデータを追加できる機能**を実装します。

### このステップの目的

- Share ExtensionからInboxにURLを追加できるようにする
- Inbox上限（50件）のチェック機能を実装
- 実データを使って動作確認ができる状態にする

### 段階的実装の位置づけ

- **006**: スキーママイグレーション（基盤のみ）✅
- **007** (本ドキュメント): Share Extension対応（Inbox追加機能）
- **008**: Repository層完成（状態移動ロジック）
- **009**: UI実装（タブとリスト表示）

**007のゴール**: SafariなどからURLを共有すると、Inboxに追加され、SwiftDataで確認できる状態にすること

---

## 前提条件

- 006が完了していること
  - AppV3Schemaが定義されている
  - 軽量マイグレーションが実装されている
  - ModelExtensions.swiftが作成されている
  - アプリが正常に起動する

---

## 実装内容

### 1. InboxConfiguration

Inboxの上限設定を定義します。

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

**技術ポイント**:
- 上限値を一箇所で管理
- 警告閾値を自動計算（将来のUI実装で使用）

### 2. URLItemRepositoryProtocol

Inbox追加に必要な最小限のプロトコルを定義します。

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
}
```

**技術ポイント**:
- 007では上記4メソッドのみ定義
- 008で状態移動メソッドを追加

### 3. URLItemRepository

Inbox追加ロジックを実装します。

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
- 上限チェックを`canAddToInbox()`で実行
- `fetchCount`でカウントのみ取得（全件取得しない）
- エラーをLocalizedErrorで定義

### 4. Share Extension更新

Share ViewControllerをInbox追加に対応させます。

```swift
//
//  ShareViewController.swift
//  ShareExtension
//

import UIKit
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private var modelContainer: ModelContainer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // ModelContainerの初期化
        do {
            let schema = Schema([
                Inbox.self,
                Bookmark.self,
                Archive.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.munakata-hisashi.ReadItLater")
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: AppMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            print("Failed to initialize ModelContainer: \(error)")
        }

        // URLの取得と保存
        Task {
            await handleSharedContent()
        }
    }

    private func handleSharedContent() async {
        guard let extensionContext = extensionContext,
              let item = extensionContext.inputItems.first as? NSExtensionItem,
              let itemProvider = item.attachments?.first else {
            completeRequest(error: ShareError.noURLFound)
            return
        }

        do {
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                let url = try await itemProvider.loadItem(
                    forTypeIdentifier: UTType.url.identifier,
                    options: nil
                ) as? URL

                guard let urlString = url?.absoluteString else {
                    completeRequest(error: ShareError.noURLFound)
                    return
                }

                let title = item.attributedContentText?.string ?? urlString
                try await saveBookmark(url: urlString, title: title)
                completeRequest(error: nil)
            }
        } catch {
            completeRequest(error: error)
        }
    }

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

    private func completeRequest(error: Error?) {
        if let error = error {
            extensionContext?.cancelRequest(withError: error)
        } else {
            extensionContext?.completeRequest(returningItems: nil)
        }
    }
}

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
- groupContainerでメインアプリとデータ共有

---

## 実装手順

### 1. InboxConfiguration.swiftを作成

**ファイルパス**: `ReadItLater/Domain/InboxConfiguration.swift`

```swift
import Foundation

enum InboxConfiguration {
    static let maxItems: Int = 50

    static var warningThreshold: Int {
        Int(Double(maxItems) * 0.8)
    }
}
```

### 2. URLItemRepositoryProtocol.swiftを作成

**ファイルパス**: `ReadItLater/Domain/URLItemRepositoryProtocol.swift`

```swift
import Foundation

protocol URLItemRepositoryProtocol {
    func addToInbox(url: String, title: String) throws
    func canAddToInbox() -> Bool
    func inboxCount() -> Int
    func remainingInboxCapacity() -> Int
}
```

### 3. URLItemRepository.swiftを作成

**ファイルパス**: `ReadItLater/Infrastructure/URLItemRepository.swift`

Inbox追加ロジックを実装します（上記のコード参照）。

### 4. ShareViewController.swiftを更新

**ファイルパス**: `ShareExtension/ShareViewController.swift`

Inbox追加に対応したコードに更新します（上記のコード参照）。

---

## 修正対象ファイル一覧

### 新規ファイル

| ファイル | 目的 |
|---------|------|
| `Domain/InboxConfiguration.swift` | Inbox上限設定 |
| `Domain/URLItemRepositoryProtocol.swift` | Repository層のプロトコル定義（Inbox操作のみ） |
| `Infrastructure/URLItemRepository.swift` | Inbox追加ロジックの実装 |

### 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `ShareExtension/ShareViewController.swift` | Inbox追加ロジックに対応 |

---

## 検証方法

### ビルド確認
```bash
mise run build
```

### 動作確認

#### 1. Share Extensionからの追加

1. アプリをビルド＆実行
2. Safariで任意のWebページを開く
3. 共有ボタンをタップ
4. 「ReadItLater」を選択
5. 成功メッセージが表示されることを確認

#### 2. データ確認

**方法A: Xcodeのデバッガーで確認**

ContentView.swiftに以下のコードを一時的に追加：

```swift
@Query private var inboxItems: [Inbox]

var body: some View {
    VStack {
        Text("Inbox count: \(inboxItems.count)")
        ForEach(inboxItems) { item in
            VStack(alignment: .leading) {
                Text(item.title ?? "No title")
                Text(item.url ?? "No URL")
                    .font(.caption)
            }
        }
    }
}
```

**方法B: SwiftDataファイルを直接確認**

```bash
# シミュレータのデータディレクトリを確認
xcrun simctl get_app_container booted com.munakata-hisashi.ReadItLater data
```

#### 3. Inbox上限確認

1. Share Extensionから50件のURLを追加
2. 51件目を追加しようとする
3. 「Inboxが上限（50件）に達しています」エラーが表示されることを確認

---

## トラブルシューティング

### Share Extensionでデータが保存されない

**原因**: App GroupsのIDが正しく設定されていない可能性

**対策**:
1. Xcodeで「Signing & Capabilities」を確認
2. メインアプリとShare Extensionの両方で同じApp Groups IDを使用
3. ID: `group.munakata-hisashi.ReadItLater`

### Inbox上限チェックが機能しない

**原因**: `fetchCount`が正しくカウントできていない可能性

**対策**:
1. デバッガーで`inboxCount()`の戻り値を確認
2. SwiftDataのストアが正しく初期化されているか確認

---

## 次のステップ

007の実装完了後、以下の順序で機能を追加していきます：

1. **008: Repository層完成** - 状態移動ロジックを実装し、ユニットテストで検証
2. **009: UI実装** - 3タブUIとスワイプアクションを実装し、エンドユーザーが操作可能に

---

## 技術的補足

### App Groupsとデータ共有

Share ExtensionとメインアプリでSwiftDataを共有するには、App Groupsを使用します：

1. **Xcode設定**:
   - メインアプリとShare Extensionの両方に「App Groups」capabilityを追加
   - 同じGroup IDを指定（例: `group.munakata-hisashi.ReadItLater`）

2. **ModelConfiguration**:
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    groupContainer: .identifier("group.munakata-hisashi.ReadItLater")
)
```

### Repository層の導入理由

- **テスト容易性**: ModelContextへの依存を注入可能にする
- **ビジネスロジックの分離**: SwiftDataの詳細をViewから隠蔽
- **再利用性**: Share ExtensionとメインアプリでRepositoryを共有

---

## 実装予定日

2026-01-18
