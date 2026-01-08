//
//  URLMetadataServiceTests.swift
//  ReadItLaterTests
//
//  Created by Claude on 2025/08/16.
//

import Foundation
import Testing
@testable import ReadItLater

@Suite
@MainActor
struct URLMetadataServiceTests {

    let service: URLMetadataService

    init() {
        service = URLMetadataService()
    }
    
    @Test func fetchMetadata_withInvalidURL_shouldThrowError() async {
        let url = URL(string: "https://invalid-domain-that-does-not-exist-12345.com")!
        
        do {
            _ = try await service.fetchMetadata(for: url)
            Issue.record("無効なURLではエラーが発生するべき")
        } catch {
            #expect(true, "期待通りエラーが発生")
        }
    }
}
