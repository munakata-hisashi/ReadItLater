# Issue 3: ModelContainer設定の分離

## 優先度
🟢 低優先度

## 概要
`ReadItLaterApp.swift` に含まれる `ModelContainer` の設定コードを Infrastructure 層に分離することで、設定の再利用性を高め、アプリのエントリポイントをシンプルに保ちます。

## 現在の問題点

### 1. アプリのエントリポイントに設定コードが混在
**ファイル**: `ReadItLaterApp.swift:14-50`

```swift
@main
struct ReadItLaterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            #if DEBUG
//            try autoreleasepool {
//                let desc = NSPersistentStoreDescription(url: modelConfiguration.url)
//                let opts = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.munakata-hisashi.ReadItLater")
//                desc.cloudKitContainerOptions = opts
//                // Load the store synchronously so it completes before initializing the
//                // CloudKit schema.
//                desc.shouldAddStoreAsynchronously = false
//                if let mom = NSManagedObjectModel.makeManagedObjectModel(for: [Item.self]) {
//                    let container = NSPersistentCloudKitContainer(name: "Items", managedObjectModel: mom)
//                    container.persistentStoreDescriptions = [desc]
//                    container.loadPersistentStores {_, err in
//                        if let err {
//                            fatalError(err.localizedDescription)
//                        }
//                    }
//                    // Initialize the CloudKit schema after the store finishes loading.
//                    try container.initializeCloudKitSchema()
//                    // Remove and unload the store from the persistent container.
//                    if let store = container.persistentStoreCoordinator.persistentStores.first {
//                        try container.persistentStoreCoordinator.remove(store)
//                    }
//                }
//            }
#endif
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**問題**:
- アプリのエントリポイントが設定詳細で肥大化
- テストやプレビューでの設定再利用が困難
- CloudKit設定のコメントアウトされたコードが混在

## リファクタリング手順

### ステップ 1: ModelContainer設定を Infrastructure 層に分離

**新規ファイル**: `Infrastructure/ModelContainerConfiguration.swift`

```swift
//
//  ModelContainerConfiguration.swift
//  ReadItLater
//
//  ModelContainer configuration for SwiftData persistence
//

import Foundation
import SwiftData

enum ModelContainerConfiguration {

    /// 本番環境用のModelContainerを作成
    ///
    /// - Returns: 永続化ストレージを使用する ModelContainer
    /// - Throws: ModelContainer の作成に失敗した場合
    static func createProductionContainer() throws -> ModelContainer {
        let schema = Schema([
            Bookmark.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: modelConfiguration
        )
    }

    /// プレビュー/テスト用のModelContainerを作成（インメモリ）
    ///
    /// - Returns: メモリ内のみで動作する ModelContainer
    /// - Throws: ModelContainer の作成に失敗した場合
    static func createPreviewContainer() throws -> ModelContainer {
        let schema = Schema([
            Bookmark.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: modelConfiguration
        )
    }

    /// サンプルデータ付きのプレビュー用ModelContainerを作成
    ///
    /// - Returns: サンプルデータを含む ModelContainer
    /// - Throws: ModelContainer の作成またはデータ挿入に失敗した場合
    static func createPreviewContainerWithSampleData() throws -> ModelContainer {
        let container = try createPreviewContainer()

        // サンプルデータの追加
        let sampleBookmarks = [
            Bookmark(url: "https://www.apple.com", title: "Apple"),
            Bookmark(url: "https://developer.apple.com", title: "Apple Developer"),
            Bookmark(url: "https://swift.org", title: "Swift.org")
        ]

        let context = container.mainContext
        for bookmark in sampleBookmarks {
            context.insert(bookmark)
        }

        return container
    }

    #if DEBUG
    /// CloudKitスキーマ初期化用のヘルパー（開発時のみ）
    ///
    /// 注意: このメソッドは開発時のCloudKitスキーマ初期化にのみ使用します。
    /// 通常の運用では使用しません。
    static func initializeCloudKitSchema() throws {
        // CloudKit スキーマ初期化のロジック
        // 現在はコメントアウトされているため、必要に応じて実装
        /*
        try autoreleasepool {
            let schema = Schema([Bookmark.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let desc = NSPersistentStoreDescription(url: modelConfiguration.url)
            let opts = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.munakata-hisashi.ReadItLater"
            )
            desc.cloudKitContainerOptions = opts
            desc.shouldAddStoreAsynchronously = false

            if let mom = NSManagedObjectModel.makeManagedObjectModel(for: [Bookmark.self]) {
                let container = NSPersistentCloudKitContainer(
                    name: "Bookmarks",
                    managedObjectModel: mom
                )
                container.persistentStoreDescriptions = [desc]
                container.loadPersistentStores { _, err in
                    if let err {
                        fatalError(err.localizedDescription)
                    }
                }
                try container.initializeCloudKitSchema()
                if let store = container.persistentStoreCoordinator.persistentStores.first {
                    try container.persistentStoreCoordinator.remove(store)
                }
            }
        }
        */
    }
    #endif
}
```

### ステップ 2: ReadItLaterApp.swift を簡素化

**ファイル**: `ReadItLaterApp.swift`

```swift
//
//  ReadItLaterApp.swift
//  ReadItLater
//
//  Created by 宗像恒 on 2025/08/02.
//

import SwiftUI
import SwiftData

@main
struct ReadItLaterApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainerConfiguration.createProductionContainer()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

### ステップ 3: プレビュー設定を更新

既存のプレビューで新しい設定を使用するように更新します。

**ファイル**: `View/ContentView.swift`

変更前:
```swift
#Preview {
    let schema = Schema([
        Bookmark.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    let modelContainer = try! ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: modelConfiguration)
    ContentView()
        .modelContainer(modelContainer)
}
```

変更後:
```swift
#Preview {
    ContentView()
        .modelContainer(try! ModelContainerConfiguration.createPreviewContainer())
}
```

**ファイル**: `View/BookmarkView.swift`

変更前:
```swift
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Bookmark.self, configurations: config)
    let example = Bookmark(url: "https://example.com")
    BookmarkView(bookmark: example)
        .modelContainer(container)
}
```

変更後:
```swift
#Preview {
    let container = try! ModelContainerConfiguration.createPreviewContainer()
    let example = Bookmark(url: "https://example.com", title: "Example")
    container.mainContext.insert(example)

    return BookmarkView(bookmark: example)
        .modelContainer(container)
}
```

### ステップ 4: テストでの利用

**ファイル**: `ReadItLaterTests/ReadItLaterTests.swift` (または新規テストファイル)

```swift
import XCTest
import SwiftData
@testable import ReadItLater

final class ModelContainerTests: XCTestCase {

    func testCreateProductionContainer() throws {
        // 本番用コンテナの作成テスト
        let container = try ModelContainerConfiguration.createProductionContainer()
        XCTAssertNotNil(container)
    }

    func testCreatePreviewContainer() throws {
        // プレビュー用コンテナの作成テスト
        let container = try ModelContainerConfiguration.createPreviewContainer()
        XCTAssertNotNil(container)

        // メモリ内のみで動作することを確認
        let bookmark = Bookmark(url: "https://test.com", title: "Test")
        container.mainContext.insert(bookmark)

        // データが挿入できることを確認
        let descriptor = FetchDescriptor<Bookmark>()
        let bookmarks = try container.mainContext.fetch(descriptor)
        XCTAssertEqual(bookmarks.count, 1)
    }

    func testCreatePreviewContainerWithSampleData() throws {
        // サンプルデータ付きコンテナの作成テスト
        let container = try ModelContainerConfiguration.createPreviewContainerWithSampleData()

        let descriptor = FetchDescriptor<Bookmark>()
        let bookmarks = try container.mainContext.fetch(descriptor)
        XCTAssertEqual(bookmarks.count, 3)
    }
}
```

## ディレクトリ構造（変更後）

```
Infrastructure/
├── URLMetadataService.swift
└── ModelContainerConfiguration.swift (新規)
```

## 期待される効果

### 1. 関心の分離
- **ReadItLaterApp**: アプリのエントリポイントのみ
- **ModelContainerConfiguration**: データ永続化の設定

### 2. 再利用性の向上
- テストで簡単にインメモリコンテナを作成
- プレビューで統一された設定を使用
- サンプルデータ付きコンテナの簡単な作成

### 3. 可読性の向上
- アプリのエントリポイントが簡潔に
- 設定のバリエーションが明確

### 4. テスタビリティの向上
- ModelContainer 設定自体のテストが可能
- テストでの設定の一貫性

## 影響範囲
- `ReadItLaterApp.swift` (簡素化)
- `Infrastructure/ModelContainerConfiguration.swift` (新規作成)
- `View/ContentView.swift` (プレビュー更新)
- `View/BookmarkView.swift` (プレビュー更新)
- テストファイル (必要に応じて更新)

## 実装後の確認事項
- [ ] アプリが正常に起動する
- [ ] データの永続化が正常に動作する
- [ ] すべてのプレビューが正常に表示される
- [ ] 既存のテストがすべてパスする
- [ ] 新しい設定のテストを追加
- [ ] CloudKit同期が引き続き機能する（該当する場合）

## 追加の改善案

### オプション 1: 環境変数による設定切り替え

```swift
enum ModelContainerConfiguration {
    static func createContainer(environment: Environment = .production) throws -> ModelContainer {
        switch environment {
        case .production:
            return try createProductionContainer()
        case .preview:
            return try createPreviewContainer()
        case .test:
            return try createPreviewContainer()
        }
    }

    enum Environment {
        case production
        case preview
        case test
    }
}
```

### オプション 2: CloudKit設定の分離

CloudKit設定が必要な場合は、さらに専用の設定クラスを作成：

```swift
enum CloudKitConfiguration {
    static let containerIdentifier = "iCloud.munakata-hisashi.ReadItLater"

    static func configureCloudKit(for configuration: ModelConfiguration) -> ModelConfiguration {
        // CloudKit設定のロジック
        return configuration
    }
}
```

## 注意事項

- この変更は既存のデータには影響しません
- 本番環境とテスト環境で異なる設定を使用できるようになります
- CloudKit初期化コードは現在コメントアウトされているため、必要に応じて有効化してください
