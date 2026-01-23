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
    func testTabBarAndNavigation() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // タブバーの存在を確認
        let tabBar = app.tabBars
        XCTAssertTrue(tabBar.firstMatch.waitForExistence(timeout: 5), "Tab bar should exist")

        // タブバーがInbox, Bookmarks, Archiveの順に並んでいることを確認
        let inboxTab = tabBar.buttons["Inbox"]
        let bookmarksTab = tabBar.buttons["Bookmarks"]
        let archiveTab = tabBar.buttons["Archive"]

        XCTAssertTrue(inboxTab.exists, "Inbox tab should exist")
        XCTAssertTrue(bookmarksTab.exists, "Bookmarks tab should exist")
        XCTAssertTrue(archiveTab.exists, "Archive tab should exist")

        // Inboxタブを選択するとナビゲーションタイトルがInboxになっている
        inboxTab.tap()
        let inboxNavigationBar = app.navigationBars["Inbox"]
        XCTAssertTrue(inboxNavigationBar.waitForExistence(timeout: 2), "Inbox navigation bar should exist")

        // Inboxのリスト画面には追加ボタンがある
        let addItemButton = app.buttons["Add Item"]
        XCTAssertTrue(addItemButton.exists, "Add Item button should exist in Inbox")

        // Bookmarksタブを選択するとナビゲーションタイトルがBookmarksになっている
        bookmarksTab.tap()
        let bookmarksNavigationBar = app.navigationBars["Bookmarks"]
        XCTAssertTrue(bookmarksNavigationBar.waitForExistence(timeout: 2), "Bookmarks navigation bar should exist")

        // Bookmarksのリスト画面には追加ボタンがない（Inboxのみ）
        XCTAssertFalse(addItemButton.exists, "Add Item button should not exist in Bookmarks")

        // Archiveタブを選択するとナビゲーションタイトルがArchiveになっている
        archiveTab.tap()
        let archiveNavigationBar = app.navigationBars["Archive"]
        XCTAssertTrue(archiveNavigationBar.waitForExistence(timeout: 2), "Archive navigation bar should exist")

        // Archiveのリスト画面には追加ボタンがない（Inboxのみ）
        XCTAssertFalse(addItemButton.exists, "Add Item button should not exist in Archive")
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
