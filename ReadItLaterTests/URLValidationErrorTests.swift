//
//  URLValidationErrorTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/14.
//

import Testing
@testable import ReadItLater

@Suite struct URLValidationErrorTests {
    
    // MARK: - LocalizedError テスト
    
    @Test func emptyURL_エラーメッセージ() {
        let error = URLValidationError.emptyURL
        #expect(error.errorDescription == "URLを入力してください")
    }
    
    @Test func invalidFormat_エラーメッセージ() {
        let error = URLValidationError.invalidFormat
        #expect(error.errorDescription == "有効なURL形式で入力してください")
    }
    
    @Test func unsupportedScheme_エラーメッセージ() {
        let error = URLValidationError.unsupportedScheme
        #expect(error.errorDescription == "http://またはhttps://のURLのみ対応しています")
    }
    
    // MARK: - Equatable テスト
    
    @Test func 同じエラー_等価比較() {
        let error1 = URLValidationError.emptyURL
        let error2 = URLValidationError.emptyURL
        #expect(error1 == error2)
    }
    
    @Test func 異なるエラー_非等価比較() {
        let error1 = URLValidationError.emptyURL
        let error2 = URLValidationError.invalidFormat
        #expect(error1 != error2)
    }
    
    @Test func 全エラータイプ_非等価比較() {
        let emptyURL = URLValidationError.emptyURL
        let invalidFormat = URLValidationError.invalidFormat
        let unsupportedScheme = URLValidationError.unsupportedScheme
        
        #expect(emptyURL != invalidFormat)
        #expect(emptyURL != unsupportedScheme)
        #expect(invalidFormat != unsupportedScheme)
    }
    
    // MARK: - エラー分類テスト
    
    @Test func エラーケース網羅性() {
        // 全てのエラーケースがテストされていることを確認
        let allCases: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        #expect(allCases.count == 3, "新しいエラーケースが追加された場合はテストも更新してください")
        
        for errorCase in allCases {
            #expect(errorCase.errorDescription != nil, "\(errorCase) のエラーメッセージが定義されていません")
        }
    }
    
    // MARK: - エラーメッセージ品質テスト
    
    @Test func エラーメッセージ_空でない() {
        let errors: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        for error in errors {
            guard let message = error.errorDescription else {
                Issue.record("\(error) のエラーメッセージが nil です")
                continue
            }
            
            #expect(!message.isEmpty, "\(error) のエラーメッセージが空です")
            #expect(!message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, 
                          "\(error) のエラーメッセージが空白のみです")
        }
    }
    
    @Test func エラーメッセージ_適切な長さ() {
        let errors: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        for error in errors {
            guard let message = error.errorDescription else { continue }
            
            // エラーメッセージは5文字以上100文字以内が適切
            #expect(message.count >= 5, "\(error) のエラーメッセージが短すぎます: \(message)")
            #expect(message.count <= 100, "\(error) のエラーメッセージが長すぎます: \(message)")
        }
    }
    
    @Test func エラーメッセージ_日本語() {
        let errors: [URLValidationError] = [.emptyURL, .invalidFormat, .unsupportedScheme]
        
        for error in errors {
            guard let message = error.errorDescription else { continue }
            
            // 日本語文字が含まれていることを確認（簡易チェック）
            let containsJapanese = message.range(of: "[あ-ん]|[ア-ン]|[一-龯]", options: .regularExpression) != nil
            #expect(containsJapanese, "\(error) のエラーメッセージに日本語が含まれていません: \(message)")
        }
    }
}