//
//  ReadItLaterUITests.swift
//  ReadItLaterUITests
//
//  Created by 宗像恒 on 2025/08/02.
//

import XCTest

final class ReadItLaterUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // アプリの主要なUI要素が存在することを確認

        // ナビゲーションタイトルが表示されることを確認
        let bookmarksNavigationBar = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNavigationBar.waitForExistence(timeout: 5), "Bookmarks navigation bar should exist")

        // 追加ボタンが存在することを確認
        let addButton = app.buttons["Add Bookmark"]
        XCTAssertTrue(addButton.exists, "Add Bookmark button should exist")

        // Editボタンが存在することを確認
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.exists, "Edit button should exist")
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
