//
//  ArchiveExportUseCaseTests.swift
//  ReadItLaterTests
//
//  Created by Codex on 2026/05/23.
//

import Foundation
import Testing
@testable import ReadItLater

@MainActor
@Suite("ArchiveExportUseCase")
struct ArchiveExportUseCaseTests {
    private let useCase = ArchiveExportUseCase()

    @Test("CSV生成: アーカイブ情報を書き出せる")
    func CSV生成_アーカイブ情報を書き出せる() throws {
        let addedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let archivedAt = Date(timeIntervalSince1970: 1_700_000_600)
        let exportedAt = Date(timeIntervalSince1970: 1_700_086_400)

        let item = ArchiveExportItem(
            title: "Example Article",
            url: "https://example.com/article",
            addedInboxAt: addedAt,
            archivedAt: archivedAt
        )

        let result = try useCase.execute(items: [item], exportedAt: exportedAt)
        let csv = try #require(String(data: result.data, encoding: .utf8))

        #expect(result.filename == "archive-\(Self.filenameDateFormatter.string(from: exportedAt)).csv")
        #expect(csv == """
        title,url,addedInboxAt,archivedAt
        Example Article,https://example.com/article,2023-11-14T22:13:20Z,2023-11-14T22:23:20Z
        """)
    }

    @Test("CSV生成: カンマと改行とダブルクオートをエスケープする")
    func CSV生成_カンマと改行とダブルクオートをエスケープする() throws {
        let item = ArchiveExportItem(
            title: "Quote \"and\"\ncomma, title",
            url: "https://example.com/a,b",
            addedInboxAt: Date(timeIntervalSince1970: 0),
            archivedAt: Date(timeIntervalSince1970: 60)
        )

        let result = try useCase.execute(items: [item], exportedAt: Date(timeIntervalSince1970: 0))
        let csv = try #require(String(data: result.data, encoding: .utf8))

        #expect(csv == """
        title,url,addedInboxAt,archivedAt
        "Quote ""and""
        comma, title","https://example.com/a,b",1970-01-01T00:00:00Z,1970-01-01T00:01:00Z
        """)
    }

    @Test("CSV生成: キャリッジリターンを含む値をエスケープする")
    func CSV生成_キャリッジリターンを含む値をエスケープする() throws {
        let item = ArchiveExportItem(
            title: "Title\rNext",
            url: "https://example.com/article",
            addedInboxAt: Date(timeIntervalSince1970: 0),
            archivedAt: Date(timeIntervalSince1970: 60)
        )

        let result = try useCase.execute(items: [item], exportedAt: Date(timeIntervalSince1970: 0))
        let csv = try #require(String(data: result.data, encoding: .utf8))

        #expect(csv == """
        title,url,addedInboxAt,archivedAt
        "Title\rNext",https://example.com/article,1970-01-01T00:00:00Z,1970-01-01T00:01:00Z
        """)
    }

    @Test("CSV生成: 空のアーカイブ一覧は失敗する")
    func CSV生成_空のアーカイブ一覧は失敗する() {
        #expect(throws: ArchiveExportError.emptyArchives) {
            try useCase.execute(items: [])
        }
    }

    private static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
