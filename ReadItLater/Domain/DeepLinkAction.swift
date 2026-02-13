//
//  DeepLinkAction.swift
//  ReadItLater
//
//  カスタムURLスキームから解析されたアクションを表すドメインモデル
//

import Foundation

/// カスタムURLスキーム（readitlater://）から解析されたアクション
enum DeepLinkAction: Equatable {
    /// URLをInboxに保存する
    /// - Parameters:
    ///   - url: 保存対象のURL文字列
    ///   - title: オプションのタイトル
    case saveToInbox(url: String, title: String?)
}

/// カスタムURLスキームのパース処理
enum DeepLinkParser {
    /// URLスキームの識別子
    static let scheme = "readitlater"

    /// パースエラー
    enum ParseError: Error, LocalizedError, Equatable {
        case unsupportedScheme
        case unknownAction(String)
        case missingURL

        var errorDescription: String? {
            switch self {
            case .unsupportedScheme:
                return "サポートされていないURLスキームです"
            case .unknownAction(let action):
                return "不明なアクションです: \(action)"
            case .missingURL:
                return "保存対象のURLが指定されていません"
            }
        }
    }

    /// URLからDeepLinkActionをパースする
    /// - Parameter url: カスタムURLスキームのURL
    /// - Returns: パースされたアクション
    /// - Throws: ParseError
    static func parse(_ url: URL) throws -> DeepLinkAction {
        guard url.scheme?.lowercased() == scheme else {
            throw ParseError.unsupportedScheme
        }

        let action = url.host(percentEncoded: false) ?? ""

        switch action {
        case "save":
            return try parseSaveAction(url)
        default:
            throw ParseError.unknownAction(action)
        }
    }

    // MARK: - Private

    private static func parseSaveAction(_ url: URL) throws -> DeepLinkAction {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ParseError.missingURL
        }

        let queryItems = components.queryItems ?? []
        let title = queryItems.first(where: { $0.name == "title" })?.value

        guard let urlParam = extractURLParameter(from: components, hasTitleParameter: title != nil),
              !urlParam.isEmpty else {
            throw ParseError.missingURL
        }

        return .saveToInbox(url: urlParam, title: title)
    }

    private static func extractURLParameter(from components: URLComponents, hasTitleParameter: Bool) -> String? {
        let queryItems = components.queryItems ?? []
        guard let parsedURL = queryItems.first(where: { $0.name == "url" })?.value else {
            return nil
        }

        let expectedItemCount = hasTitleParameter ? 2 : 1
        let hasUnexpectedItems = queryItems.count > expectedItemCount

        guard let rawQuery = components.percentEncodedQuery,
              hasUnexpectedItems,
              parsedURL.contains("?"),
              let reconstructedURL = reconstructURLParameter(from: rawQuery, hasTitleParameter: hasTitleParameter),
              !reconstructedURL.isEmpty else {
            return parsedURL
        }

        return reconstructedURL
    }

    private static func reconstructURLParameter(from rawQuery: String, hasTitleParameter: Bool) -> String? {
        let urlStart: String.Index
        if rawQuery.hasPrefix("url=") {
            urlStart = rawQuery.index(rawQuery.startIndex, offsetBy: 4)
        } else if let range = rawQuery.range(of: "&url=") {
            urlStart = range.upperBound
        } else {
            return nil
        }

        let urlEnd: String.Index
        if hasTitleParameter,
           let titleRange = rawQuery.range(
            of: "&title=",
            options: [],
            range: urlStart..<rawQuery.endIndex
           ) {
            urlEnd = titleRange.lowerBound
        } else {
            urlEnd = rawQuery.endIndex
        }

        let encodedURL = String(rawQuery[urlStart..<urlEnd])
        return encodedURL.removingPercentEncoding ?? encodedURL
    }
}
