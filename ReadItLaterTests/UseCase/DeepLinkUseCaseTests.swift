//
//  DeepLinkUseCaseTests.swift
//  ReadItLaterTests
//
//  DeepLinkUseCaseのユニットテスト
//

import Testing
import Foundation
@testable import ReadItLater

@Suite("DeepLinkUseCase")
@MainActor
struct DeepLinkUseCaseTests {

    // MARK: - 成功ケース

    @Test("save成功 - URLとタイトル指定")
    func testExecuteSuccess_WithURLAndTitle() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        let url = URL(string: "readitlater://save?url=https%3A%2F%2Fexample.com&title=Example%20Title")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            #expect(mockRepository.addCalled)
            #expect(mockRepository.addedURL == "https://example.com")
            #expect(mockRepository.addedTitle == "Example Title")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("save成功 - タイトルなし（メタデータ取得成功）")
    func testExecuteSuccess_WithoutTitle_MetadataSuccess() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        mockMetadataService.metadataToReturn = URLMetadata(
            title: "Fetched Title",
            description: nil
        )
        let mockRepository = MockInboxRepository()

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        let url = URL(string: "readitlater://save?url=https%3A%2F%2Fexample.com")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            #expect(mockRepository.addCalled)
            #expect(mockRepository.addedURL == "https://example.com")
            #expect(mockRepository.addedTitle == "Fetched Title")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("save成功 - タイトルなし（メタデータ取得失敗、ホスト名で代用）")
    func testExecuteSuccess_WithoutTitle_MetadataFailure() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        mockMetadataService.errorToThrow = NSError(domain: "test", code: 1)
        let mockRepository = MockInboxRepository()

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        let url = URL(string: "readitlater://save?url=https%3A%2F%2Fexample.com")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            #expect(mockRepository.addCalled)
            #expect(mockRepository.addedURL == "https://example.com")
            #expect(mockRepository.addedTitle == "Example.Com")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    // MARK: - パースエラー

    @Test("エラー - サポートされていないスキーム")
    func testExecuteFailure_UnsupportedScheme() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        let url = URL(string: "https://example.com")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .parseError(.unsupportedScheme))
            #expect(!mockRepository.addCalled)
        }
    }

    @Test("エラー - 不明なアクション")
    func testExecuteFailure_UnknownAction() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        let url = URL(string: "readitlater://unknown")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .parseError(.unknownAction("unknown")))
            #expect(!mockRepository.addCalled)
        }
    }

    @Test("エラー - saveでURL未指定")
    func testExecuteFailure_MissingURL() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        let url = URL(string: "readitlater://save")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .parseError(.missingURL))
            #expect(!mockRepository.addCalled)
        }
    }

    // MARK: - 保存エラー

    @Test("エラー - Inbox上限")
    func testExecuteFailure_InboxFull() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()
        mockRepository.canAddResult = false

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        let url = URL(string: "readitlater://save?url=https%3A%2F%2Fexample.com&title=Test")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .saveFailed(.inboxFull))
            #expect(!mockRepository.addCalled)
        }
    }

    @Test("エラー - 無効なURL形式")
    func testExecuteFailure_InvalidURL() async {
        // Given
        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = DeepLinkUseCase(
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // ftp://はInboxURLで弾かれる
        let url = URL(string: "readitlater://save?url=ftp%3A%2F%2Fexample.com")!

        // When
        let result = await useCase.execute(url: url)

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .saveFailed(.inboxCreationFailed(.unsupportedScheme)))
            #expect(!mockRepository.addCalled)
        }
    }
}
