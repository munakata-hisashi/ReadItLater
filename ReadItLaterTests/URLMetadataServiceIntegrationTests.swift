//
//  URLMetadataServiceIntegrationTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/16.
//

import XCTest
@testable import ReadItLater

@MainActor
final class URLMetadataServiceIntegrationTests: XCTestCase {
    
    private var service: URLMetadataService!
    
    override func setUp() {
        super.setUp()
        service = URLMetadataService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testFetchMetadata_withZennArticle_shouldReturnCorrectTitle() async throws {
        let url = URL(string: "https://zenn.dev/medicalforce/articles/8bc0b6afbbb8a7")!
        
        do {
            let metadata = try await service.fetchMetadata(for: url)
            print("取得されたタイトル: '\(metadata.title ?? "nil")'")
            
            XCTAssertNotNil(metadata.title, "タイトルが取得されるべき")
            XCTAssertFalse(metadata.title?.isEmpty ?? true, "タイトルは空であってはならない")
            
            // Zenn.devではなく、記事のタイトルが取得されることを期待
            XCTAssertNotEqual(metadata.title, "Zenn", "記事のタイトルであるべき、サイト名ではない")
            XCTAssertNotEqual(metadata.title, "Zenn.dev", "記事のタイトルであるべき、サイト名ではない")
            
            print("テスト成功: タイトル = '\(metadata.title ?? "nil")'")
            
        } catch {
            print("メタデータ取得エラー: \(error)")
            XCTFail("メタデータの取得に失敗しました: \(error)")
        }
    }
    
    func testFetchMetadata_withAppleSite_shouldReturnCorrectTitle() async throws {
        let url = URL(string: "https://www.apple.com")!
        
        do {
            let metadata = try await service.fetchMetadata(for: url)
            print("Apple サイトのタイトル: '\(metadata.title ?? "nil")'")
            
            XCTAssertNotNil(metadata.title, "タイトルが取得されるべき")
            XCTAssertFalse(metadata.title?.isEmpty ?? true, "タイトルは空であってはならない")
            
        } catch {
            print("Apple サイトのメタデータ取得エラー: \(error)")
            XCTFail("メタデータの取得に失敗しました: \(error)")
        }
    }
}