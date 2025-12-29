//
//  URLMetadataServiceTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/16.
//

import XCTest
@testable import ReadItLater

@MainActor
final class URLMetadataServiceTests: XCTestCase {
    
    private var service: URLMetadataService!
    
    override func setUp() {
        super.setUp()
        service = URLMetadataService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testFetchMetadata_withValidURL_shouldReturnMetadata() async throws {
        let url = URL(string: "https://www.apple.com")!
        
        let metadata = try await service.fetchMetadata(for: url)
        
        XCTAssertNotNil(metadata.title)
        XCTAssertFalse(metadata.title?.isEmpty ?? true, "タイトルが取得されるべき")
    }
    
    func testFetchMetadata_withInvalidURL_shouldThrowError() async {
        let url = URL(string: "https://invalid-domain-that-does-not-exist-12345.com")!
        
        do {
            _ = try await service.fetchMetadata(for: url)
            XCTFail("無効なURLではエラーが発生するべき")
        } catch {
            XCTAssertTrue(true, "期待通りエラーが発生")
        }
    }
}