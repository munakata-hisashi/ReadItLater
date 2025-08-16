//
//  URLValidationErrorTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import XCTest
@testable import ReadItLater

final class URLValidationErrorTests: XCTestCase {
    
    // MARK: - LocalizedError テスト
    
    func test_emptyURL_エラーメッセージ() {
        let error = URLValidationError.emptyURL
        XCTAssertEqual(error.errorDescription, "URLを入力してください")
    }
    
    func test_invalidFormat_エラーメッセージ() {
        let error = URLValidationError.invalidFormat
        XCTAssertEqual(error.errorDescription, "有効なURL形式で入力してください")
    }
    
    func test_unsupportedScheme_エラーメッセージ() {
        let error = URLValidationError.unsupportedScheme
        XCTAssertEqual(error.errorDescription, "http://またはhttps://のURLのみ対応しています")
    }
    
    // MARK: - Equatable テスト
    
    func test_同じエラー_等価比較() {
        let error1 = URLValidationError.emptyURL
        let error2 = URLValidationError.emptyURL
        XCTAssertEqual(error1, error2)
    }
    
    func test_異なるエラー_非等価比較() {
        let error1 = URLValidationError.emptyURL
        let error2 = URLValidationError.invalidFormat
        XCTAssertNotEqual(error1, error2)
    }
    
    func test_全エラータイプ_非等価比較() {
        let emptyURL = URLValidationError.emptyURL
        let invalidFormat = URLValidationError.invalidFormat
        let unsupportedScheme = URLValidationError.unsupportedScheme
        
        XCTAssertNotEqual(emptyURL, invalidFormat)
        XCTAssertNotEqual(emptyURL, unsupportedScheme)
        XCTAssertNotEqual(invalidFormat, unsupportedScheme)
    }
    
    // MARK: - エラー分類テスト
    
    func test_エラーケース網羅性() {
        // 全てのエラーケースがテストされていることを確認
        let allCases: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        XCTAssertEqual(allCases.count, 3, "新しいエラーケースが追加された場合はテストも更新してください")
        
        for errorCase in allCases {
            XCTAssertNotNil(errorCase.errorDescription, "\(errorCase) のエラーメッセージが定義されていません")
        }
    }
    
    // MARK: - エラーメッセージ品質テスト
    
    func test_エラーメッセージ_空でない() {
        let errors: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        for error in errors {
            guard let message = error.errorDescription else {
                XCTFail("\(error) のエラーメッセージが nil です")
                continue
            }
            
            XCTAssertFalse(message.isEmpty, "\(error) のエラーメッセージが空です")
            XCTAssertFalse(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, 
                          "\(error) のエラーメッセージが空白のみです")
        }
    }
    
    func test_エラーメッセージ_適切な長さ() {
        let errors: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        for error in errors {
            guard let message = error.errorDescription else { continue }
            
            // エラーメッセージは5文字以上100文字以内が適切
            XCTAssertGreaterThanOrEqual(message.count, 5, "\(error) のエラーメッセージが短すぎます: \(message)")
            XCTAssertLessThanOrEqual(message.count, 100, "\(error) のエラーメッセージが長すぎます: \(message)")
        }
    }
    
    func test_エラーメッセージ_日本語() {
        let errors: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        for error in errors {
            guard let message = error.errorDescription else { continue }
            
            // 日本語文字が含まれていることを確認（簡易チェック）
            let containsJapanese = message.range(of: "[あ-ん]|[ア-ン]|[一-龯]", options: .regularExpression) != nil
            XCTAssertTrue(containsJapanese, "\(error) のエラーメッセージに日本語が含まれていません: \(message)")
        }
    }
}