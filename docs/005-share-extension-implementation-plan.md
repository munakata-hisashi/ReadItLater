# Safari共有シート対応 Share Extension実装計画

## 概要
SafariやブラウザアプリからURLを共有シートで直接保存できるShare Extension機能を追加します。

## 要件
- **UI**: UIなし、共有シートから選択すると即座に保存完了
- **タイトル取得**: URLMetadataService（LinkPresentation）でページタイトル自動取得
- **データ共有**: App Groupsを使用してメインアプリとSwiftDataコンテナを共有
- **CloudKit**: 既存のCloudKit統合（`iCloud.munakata-hisashi.ReadItLater`）を維持

---

## 実装手順

### Phase 1: App Groups設定

#### 1.1 エンタイトルメント変更

**メインアプリ**: `ReadItLater/ReadItLater.entitlements`
- `com.apple.security.application-groups` キーを追加
- 値: `group.munakata-hisashi.ReadItLater`

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.munakata-hisashi.ReadItLater</string>
</array>
```

**Share Extension**: `ShareExtension/ShareExtension.entitlements` (新規作成)
- CloudKit設定（既存のiCloudコンテナ使用）
- App Groups設定（同じグループ識別子）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.munakata-hisashi.ReadItLater</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.munakata-hisashi.ReadItLater</string>
    </array>
</dict>
</plist>
```

#### 1.2 Xcode Capabilities設定
- 両ターゲット（ReadItLater, ShareExtension）で `App Groups` Capabilityを有効化
- `group.munakata-hisashi.ReadItLater` をチェック

---

### Phase 2: 共有インフラ構築

#### 2.1 ModelContainerFactory作成

**新規ファイル**: `Shared/ModelContainerFactory.swift`

App Groups対応の共有SwiftDataストアを提供:

```swift
import Foundation
import SwiftData

enum ModelContainerFactory {
    /// App Groups共有ストレージURL
    static var sharedStoreURL: URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.munakata-hisashi.ReadItLater"
        ) else {
            fatalError("App Groups container not found")
        }
        return containerURL.appendingPathComponent("ReadItLater.store")
    }

    /// 共有ModelContainer作成
    static func createSharedContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([Bookmark.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: inMemory ? nil : sharedStoreURL,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: modelConfiguration
        )
    }
}
```

**Target Membership**: ReadItLater + ShareExtension

#### 2.2 ReadItLaterApp.swiftリファクタリング

**変更ファイル**: `ReadItLater/ReadItLaterApp.swift`

行13-49のModelContainer初期化コードを以下に置き換え:

```swift
var sharedModelContainer: ModelContainer = {
    do {
        return try ModelContainerFactory.createSharedContainer()
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

#### 2.3 既存ファイルのTarget Membership追加

以下のファイルを **ShareExtensionターゲットにも追加**:

**Domain層**:
- `Domain/Bookmark.swift`
- `Domain/BookmarkCreation.swift`
- `Domain/BookmarkURL.swift`
- `Domain/BookmarkTitle.swift`
- `Domain/URLValidationError.swift`

**Migration層**:
- `Migration/VersionedSchema.swift`
- `Migration/MigrationPlan.swift`

**Infrastructure層**:
- `Infrastructure/URLMetadataService.swift`

---

### Phase 3: Share Extension Target作成

#### 3.1 新規Target作成

Xcodeで以下の設定でShare Extension Targetを追加:
- **Target名**: ShareExtension
- **Bundle ID**: `munakata-hisashi.ReadItLater.ShareExtension`
- **Platform**: iOS 18.1+
- **Development Team**: `RDL87GQ43U`
- **Entitlements**: `ShareExtension/ShareExtension.entitlements`

#### 3.2 Info.plist設定

**ファイル**: `ShareExtension/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.share-services</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsFileWithMaxCount</key>
            <integer>0</integer>
        </dict>
    </dict>
</dict>
</plist>
```

#### 3.3 ShareViewController実装

**新規ファイル**: `ShareExtension/ShareViewController.swift`

```swift
import UIKit
import SwiftData

@MainActor
final class ShareViewController: UIViewController {

    private var modelContainer: ModelContainer?
    private let metadataService = URLMetadataService()

    override func viewDidLoad() {
        super.viewDidLoad()

        // ModelContainer初期化
        do {
            modelContainer = try ModelContainerFactory.createSharedContainer()
        } catch {
            completeRequest(with: .failure(ShareError.containerInitFailed))
            return
        }

        // URL処理
        Task {
            await processSharedURL()
        }
    }

    private func processSharedURL() async {
        do {
            // 1. URL抽出
            guard let url = try await extractURL() else {
                throw ShareError.noURLFound
            }

            // 2. タイトル取得（非同期）
            let title = await fetchTitle(for: url)

            // 3. ブックマーク保存
            try await saveBookmark(url: url.absoluteString, title: title)

            // 4. 成功完了
            completeRequest(with: .success(()))

        } catch {
            completeRequest(with: .failure(error))
        }
    }

    private func extractURL() async throws -> URL? {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return nil
        }

        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            return try await withCheckedThrowingContinuation { continuation in
                itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (item, error) in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = item as? URL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        return nil
    }

    private func fetchTitle(for url: URL) async -> String? {
        do {
            let metadata = try await metadataService.fetchMetadata(for: url)
            return metadata.title
        } catch {
            // タイトル取得失敗時はnilを返す（BookmarkCreationがホスト名で代用）
            return nil
        }
    }

    private func saveBookmark(url: String, title: String?) async throws {
        guard let container = modelContainer else {
            throw ShareError.containerInitFailed
        }

        // 既存のBookmarkCreationロジックを使用
        let result = Bookmark.create(from: url, title: title)

        switch result {
        case .success(let bookmarkData):
            let context = ModelContext(container)
            let bookmark = Bookmark(url: bookmarkData.url, title: bookmarkData.title)
            context.insert(bookmark)
            try context.save()

        case .failure(let error):
            throw ShareError.bookmarkCreationFailed(error)
        }
    }

    private func completeRequest(with result: Result<Void, Error>) {
        switch result {
        case .success:
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        case .failure(let error):
            extensionContext?.cancelRequest(withError: error as NSError)
        }
    }
}

enum ShareError: LocalizedError {
    case noURLFound
    case containerInitFailed
    case bookmarkCreationFailed(Bookmark.CreationError)

    var errorDescription: String? {
        switch self {
        case .noURLFound:
            return "URLが見つかりませんでした"
        case .containerInitFailed:
            return "データベースの初期化に失敗しました"
        case .bookmarkCreationFailed(let error):
            return "ブックマークの作成に失敗しました: \(error.localizedDescription)"
        }
    }
}
```

---

### Phase 4: テスト

#### 4.1 ビルド確認
```bash
mise run build
```

#### 4.2 動作確認手順
1. Simulatorでメインアプリを起動
2. Safariで任意のページを開く
3. 共有ボタンをタップ
4. アクションシートに「ReadItLater」が表示されることを確認
5. タップして保存
6. メインアプリに戻り、新しいブックマークが追加されていることを確認

#### 4.3 エラーケーステスト
- 無効なURL（スキームなし、ホストなし）
- ネットワークエラー時のタイトル取得
- メインアプリと同時保存時の動作

---

## 重要ファイル一覧

### 変更ファイル
- `ReadItLater/ReadItLater.entitlements` - App Groups追加
- `ReadItLater/ReadItLaterApp.swift` - ModelContainer初期化ロジック変更

### 新規ファイル
- `Shared/ModelContainerFactory.swift` - 共有ModelContainer生成
- `ShareExtension/ShareExtension.entitlements` - Share Extension権限設定
- `ShareExtension/Info.plist` - Extension設定
- `ShareExtension/ShareViewController.swift` - Share Extension実装

### Target Membership追加（既存ファイル）
- Domain層全体（5ファイル）
- Migration層全体（2ファイル）
- URLMetadataService.swift

---

## 実装フロー

```
[Safari共有ボタン]
    ↓
[共有シート - ReadItLater選択]
    ↓
ShareViewController.viewDidLoad()
    ↓ ModelContainerFactory.createSharedContainer()
    ↓ (App Groups: group.munakata-hisashi.ReadItLater)
    ↓
processSharedURL()
    ↓ extractURL() - NSExtensionContextからURL取得
    ↓ fetchTitle() - LinkPresentationでタイトル取得（非同期）
    ↓ saveBookmark() - Bookmark.create() + ModelContext.save()
    ↓
completeRequest() - 共有シート閉じる
    ↓
[メインアプリで@Query自動更新 - 新ブックマーク表示]
```

---

## 考慮事項

### メモリ制限
- Share Extensionは約16-30MBのメモリ制限あり
- URLMetadataServiceは軽量（LinkPresentationのみ）で問題なし

### タイムアウト
- LinkPresentationのメタデータ取得は数秒かかる可能性あり
- タイトル取得失敗時は自動的にホスト名で代用（BookmarkTitle.fromURL）

### CloudKit同期
- SwiftDataとCloudKitの統合は自動
- Share Extensionでの保存後、システムが自動的に同期
- メインアプリの@Queryが変更を検知して自動更新

### エラーハンドリング
- URL抽出失敗: ShareError.noURLFound
- タイトル取得失敗: 続行（ホスト名で代用）
- URL検証失敗: ShareError.bookmarkCreationFailed
- 全エラーはLocalizedErrorで日本語メッセージ表示

---

## アーキテクチャの利点

### 既存コードの再利用
- Domain層のBookmarkCreationロジックをそのまま活用
- URL検証、タイトル処理のロジックが一元化
- メインアプリとShare Extensionで一貫性のある動作

### App Groups設計
- SwiftDataコンテナを安全に共有
- CloudKitとの統合を維持
- 将来的な他のExtensionへの拡張も容易

### エラーハンドリング
- LocalizedErrorで日本語のエラーメッセージ
- フォールバック処理（タイトル取得失敗時）
- ユーザーフレンドリーな体験

---

## 実装日: 2026-01-05
