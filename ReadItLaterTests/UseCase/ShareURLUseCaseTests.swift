//
//  ShareURLUseCaseTests.swift
//  ReadItLaterTests
//
//  Created by Claude Code on 2026/01/24.
//

import Testing
import Foundation
@testable import ReadItLater

@Suite("ShareURLUseCase")
@MainActor
struct ShareURLUseCaseTests {

    // MARK: - 成功ケース

    @Test("URL保存成功 - タイトルあり")
    func testExecuteSuccess_WithTitle() async {
        // Given
        let mockItemProvider = MockExtensionItemProvider()
        mockItemProvider.urlToReturn = URL(string: "https://example.com")
        mockItemProvider.titleToReturn = "Example Title"

        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = ShareURLUseCase(
            itemProvider: mockItemProvider,
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // When
        let result = await useCase.execute()

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

    @Test("URL保存成功 - タイトルなし（メタデータ取得成功）")
    func testExecuteSuccess_WithoutTitle_MetadataSuccess() async {
        // Given
        let mockItemProvider = MockExtensionItemProvider()
        mockItemProvider.urlToReturn = URL(string: "https://example.com")
        mockItemProvider.titleToReturn = nil

        let mockMetadataService = MockURLMetadataService()
        mockMetadataService.metadataToReturn = URLMetadata(
            title: "Metadata Title",
            description: nil
        )

        let mockRepository = MockInboxRepository()

        let useCase = ShareURLUseCase(
            itemProvider: mockItemProvider,
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success:
            #expect(mockRepository.addCalled)
            #expect(mockRepository.addedURL == "https://example.com")
            #expect(mockRepository.addedTitle == "Metadata Title")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("URL保存成功 - タイトルなし（メタデータ取得失敗、ホスト名で代用）")
    func testExecuteSuccess_WithoutTitle_MetadataFailure_FallbackToHost() async {
        // Given
        let mockItemProvider = MockExtensionItemProvider()
        mockItemProvider.urlToReturn = URL(string: "https://example.com")
        mockItemProvider.titleToReturn = nil

        let mockMetadataService = MockURLMetadataService()
        mockMetadataService.errorToThrow = NSError(domain: "test", code: 1)

        let mockRepository = MockInboxRepository()

        let useCase = ShareURLUseCase(
            itemProvider: mockItemProvider,
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success:
            #expect(mockRepository.addCalled)
            #expect(mockRepository.addedURL == "https://example.com")
            // タイトルはnilだがBookmarkCreationがホスト名で代用するため保存は成功
            #expect(mockRepository.addedTitle == "Example.Com")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    // MARK: - エラーケース

    @Test("URL抽出失敗 - URLなし")
    func testExecuteFailure_NoURL() async {
        // Given
        let mockItemProvider = MockExtensionItemProvider()
        mockItemProvider.urlToReturn = nil

        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = ShareURLUseCase(
            itemProvider: mockItemProvider,
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .noURLFound)
            #expect(!mockRepository.addCalled)
        }
    }

    @Test("Inbox上限エラー")
    func testExecuteFailure_InboxFull() async {
        // Given
        let mockItemProvider = MockExtensionItemProvider()
        mockItemProvider.urlToReturn = URL(string: "https://example.com")
        mockItemProvider.titleToReturn = "Test Title"

        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()
        mockRepository.canAddResult = false // Inbox上限

        let useCase = ShareURLUseCase(
            itemProvider: mockItemProvider,
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .inboxFull)
            #expect(!mockRepository.addCalled)
        }
    }

    @Test("無効なURL形式エラー")
    func testExecuteFailure_InvalidURL() async {
        // Given
        let mockItemProvider = MockExtensionItemProvider()
        // URLオブジェクトは作れるが、スキームがない無効なURL
        mockItemProvider.urlToReturn = URL(string: "not-a-valid-url")
        mockItemProvider.titleToReturn = "Test"

        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = ShareURLUseCase(
            itemProvider: mockItemProvider,
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            // BookmarkCreationがURL検証でエラーを返す
            if case .bookmarkCreationFailed = error {
                #expect(true)
            } else {
                Issue.record("Expected bookmarkCreationFailed error but got: \(error)")
            }
            #expect(!mockRepository.addCalled)
        }
    }

    @Test("ExtensionItemProvider抽出エラー")
    func testExecuteFailure_ItemProviderError() async {
        // Given
        let mockItemProvider = MockExtensionItemProvider()
        mockItemProvider.errorToThrow = InboxSaveError.noURLFound

        let mockMetadataService = MockURLMetadataService()
        let mockRepository = MockInboxRepository()

        let useCase = ShareURLUseCase(
            itemProvider: mockItemProvider,
            metadataService: mockMetadataService,
            repository: mockRepository
        )

        // When
        let result = await useCase.execute()

        // Then
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .noURLFound)
            #expect(!mockRepository.addCalled)
        }
    }
}
