//
//  ArchiveExportUseCase.swift
//  ReadItLater
//
//  Created by Codex on 2026/05/23.
//

import Foundation

struct ArchiveExportItem {
    let title: String
    let url: String
    let addedInboxAt: Date
    let archivedAt: Date

    init(title: String, url: String, addedInboxAt: Date, archivedAt: Date) {
        self.title = title
        self.url = url
        self.addedInboxAt = addedInboxAt
        self.archivedAt = archivedAt
    }

    @MainActor
    init(archive: Archive) {
        self.title = archive.title ?? ""
        self.url = archive.url ?? ""
        self.addedInboxAt = archive.addedInboxAt
        self.archivedAt = archive.archivedAt
    }
}

struct ArchiveExportResult {
    let filename: String
    let data: Data
}

enum ArchiveExportError: Error, Equatable {
    case emptyArchives
    case encodingFailed
}

struct ArchiveExportUseCase {
    func execute(items: [ArchiveExportItem], exportedAt: Date = .now) throws -> ArchiveExportResult {
        guard !items.isEmpty else {
            throw ArchiveExportError.emptyArchives
        }

        let csv = makeCSV(from: items)

        guard let data = csv.data(using: .utf8) else {
            throw ArchiveExportError.encodingFailed
        }

        return ArchiveExportResult(
            filename: makeFilename(exportedAt: exportedAt),
            data: data
        )
    }

    private func makeCSV(from items: [ArchiveExportItem]) -> String {
        let header = "title,url,addedInboxAt,archivedAt"
        let rows = items.map { item in
            [
                escapeCSVField(item.title),
                escapeCSVField(item.url),
                escapeCSVField(Self.dateFormatter.string(from: item.addedInboxAt)),
                escapeCSVField(Self.dateFormatter.string(from: item.archivedAt))
            ]
            .joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private func makeFilename(exportedAt: Date) -> String {
        "archive-\(Self.filenameDateFormatter.string(from: exportedAt)).csv"
    }

    private func escapeCSVField(_ value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        guard escapedValue.contains(",") || escapedValue.contains("\"") || escapedValue.contains("\n") else {
            return escapedValue
        }

        return "\"\(escapedValue)\""
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
