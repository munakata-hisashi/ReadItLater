# 010: ShareViewControllerテスト可能化実装

## 概要
ShareViewControllerのビジネスロジックをUseCase層に分離し、依存性注入によりユニットテスト可能にする。

## 背景
`ShareViewController.swift`（186行）には以下のテスト困難な依存があった：
- `extensionContext` - システム提供のNSExtensionContext
- `ModelContainerFactory.createSharedContainer()` - 直接呼び出し
- `URLMetadataService()` - 直接インスタンス化
- `InboxRepository(modelContext:)` - 直接インスタンス化

これらの依存により、ShareExtensionのビジネスロジックをユニットテストすることが困難だった。

## 設計方針

### アーキテクチャ

```
ShareViewController (薄いコーディネーター)
       │
       ▼
ShareURLUseCase (ビジネスロジック - テスト対象)
       │
       ▼ 依存性注入 (Protocols)
┌──────────────────────────────────────────────┐
│ ExtensionItemProviderProtocol                │
│ URLMetadataServiceProtocol                   │
│ InboxRepositoryProtocol (既存)               │
└──────────────────────────────────────────────┘
```

### UseCaseインターフェース

```swift
@MainActor
protocol ShareURLUseCaseProtocol {
    func execute() async -> Result<Void, ShareError>
}

@MainActor
final class ShareURLUseCase: ShareURLUseCaseProtocol {
    init(
        itemProvider: ExtensionItemProviderProtocol,
        metadataService: URLMetadataServiceProtocol,
        repository: InboxRepositoryProtocol
    )

    func execute() async -> Result<Void, ShareError>
    // 1. URL抽出 → 2. タイトル取得 → 3. 検証 → 4. 保存
}
```

## 実装内容

### 新規作成ファイル

#### Domain層（プロトコル定義）
- `Domain/ShareError.swift` - エラー型（既存コードから分離、Equatable準拠）
- `Domain/URLMetadataServiceProtocol.swift` - URLMetadataServiceの抽象化
- `Domain/ExtensionItemProviderProtocol.swift` - NSExtensionItem抽象化
- `Domain/ShareURLUseCaseProtocol.swift` - UseCaseプロトコル

#### UseCase層
- `UseCase/ShareURLUseCase.swift` - ビジネスロジック本体

#### Infrastructure層
- `Infrastructure/ExtensionItemProvider.swift` - NSExtensionItemのラッパー

#### テスト用モック
- `ReadItLaterTests/Mocks/MockExtensionItemProvider.swift`
- `ReadItLaterTests/Mocks/MockURLMetadataService.swift`
- `ReadItLaterTests/Mocks/MockInboxRepository.swift`

#### テストファイル
- `ReadItLaterTests/UseCase/ShareURLUseCaseTests.swift` - 6テストケース

### 変更した既存ファイル

#### Infrastructure/URLMetadataService.swift
`URLMetadataServiceProtocol`準拠を追加:
```swift
@MainActor
final class URLMetadataService: URLMetadataServiceProtocol {
    // 既存実装
}
```

#### ShareExtension/ShareViewController.swift
UseCase使用にリファクタリング（186行→70行に削減）:
```swift
@MainActor
final class ShareViewController: UIViewController {
    private func processSharedURL() async {
        guard let container = modelContainer else {
            completeRequest(with: .failure(ShareError.containerInitFailed))
            return
        }

        // 依存性を組み立て
        let itemProvider = ExtensionItemProvider(extensionContext: extensionContext)
        let metadataService = URLMetadataService()
        let context = ModelContext(container)
        let repository = InboxRepository(modelContext: context)

        // UseCaseを実行
        let useCase = ShareURLUseCase(
            itemProvider: itemProvider,
            metadataService: metadataService,
            repository: repository
        )

        let result = await useCase.execute()
        completeRequest(with: result)
    }
}
```

#### ReadItLater.xcodeproj/project.pbxproj
新規ファイルをShareExtensionターゲットに追加:
- Domain/ExtensionItemProviderProtocol.swift
- Domain/ShareError.swift
- Domain/ShareURLUseCaseProtocol.swift
- Domain/URLMetadataServiceProtocol.swift
- Infrastructure/ExtensionItemProvider.swift
- UseCase/ShareURLUseCase.swift

## テストケース

### 成功ケース
1. ✅ URL保存成功 - タイトルあり
2. ✅ URL保存成功 - タイトルなし（メタデータ取得成功）
3. ✅ URL保存成功 - タイトルなし（メタデータ取得失敗、ホスト名で代用）

### エラーケース
4. ✅ URL抽出失敗 - URLなし
5. ✅ Inbox上限エラー
6. ✅ 無効なURL形式エラー

## テスト可能になった項目
- ✅ URL/タイトルの抽出ロジック
- ✅ 保存処理（Inbox追加）
- ✅ Inbox上限チェック
- ✅ エラーハンドリング
- ✅ メタデータ取得失敗時のフォールバック

## 技術的注意点

### Swift 6 Concurrency
`ExtensionItemProvider`でのNSExtensionContext扱いにMain Actor隔離を適用:
```swift
// プロトコル
protocol ExtensionItemProviderProtocol {
    @MainActor
    func extractURLAndTitle() async throws -> (url: URL, title: String?)
}

// 実装
final class ExtensionItemProvider: ExtensionItemProviderProtocol {
    @MainActor
    func extractURLAndTitle() async throws -> (url: URL, title: String?) {
        // NSExtensionContextへのアクセスはMain Actorで隔離
    }
}
```

### プロジェクトファイル管理
Xcode 15+の`PBXFileSystemSynchronizedBuildFileExceptionSet`を使用:
- `membershipExceptions`リストに新規ファイルを追加することでターゲットメンバーシップを管理

## 成果

### コード品質向上
- ShareViewControllerの責務を分離（UI処理 vs ビジネスロジック）
- 行数削減: 186行 → 70行（62%削減）
- テストカバレッジ向上: ShareExtensionのビジネスロジックがテスト可能に

### 保守性向上
- プロトコルベースの設計により、モック差し替えが容易
- 各層の責務が明確化
- 依存性注入により、テストが高速で安定

## 検証方法

### ユニットテスト
```bash
mise run u
```

### 動作確認
1. シミュレーターでアプリを起動
2. Safariで任意のWebページを開く
3. 共有ボタン → ReadItLaterを選択
4. URLがInboxに追加されることを確認

## 今後の改善案

1. **ShareViewControllerのUIテスト**
   - 現在はビジネスロジックのみテスト可能
   - UIレベルのテストは別途検討が必要

2. **エラーアラート表示のテスト**
   - 現在はUseCaseまでのテスト
   - アラート表示ロジックのテストは未実装

3. **パフォーマンステスト**
   - メタデータ取得の遅延時のタイムアウト処理
   - 大量URL処理時の挙動

## 関連ドキュメント
- [005: Share Extension実装計画](./005-share-extension-implementation-plan.md)
- [007: Inbox + Share Extension](./007-inbox-share-extension.md)
- [008: Repository層状態移動ロジック](./008-repository-state-transitions.md)
