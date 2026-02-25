//
//  ReadItLaterUITests.swift
//  ReadItLaterUITests
//
//  Created by 宗像恒 on 2025/08/02.
//

import Foundation
import XCTest

final class ReadItLaterUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testTabBarAndNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // フローティングタブバーのボタン存在を確認
        let inboxTab = app.buttons["Inbox"]
        let bookmarksTab = app.buttons["Bookmarks"]
        let archiveTab = app.buttons["Archive"]

        XCTAssertTrue(inboxTab.waitForExistence(timeout: 5), "Inbox tab button should exist")
        XCTAssertTrue(bookmarksTab.exists, "Bookmarks tab button should exist")
        XCTAssertTrue(archiveTab.exists, "Archive tab button should exist")

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
    func testAddURLFromInbox() throws {
        let app = XCUIApplication()
        app.launch()

        let inboxTab = app.buttons["Inbox"]
        XCTAssertTrue(inboxTab.waitForExistence(timeout: 5), "Inbox tab button should exist")
        inboxTab.tap()

        let addItemButton = app.buttons["Add Item"]
        XCTAssertTrue(addItemButton.waitForExistence(timeout: 5), "Add Item button should exist in Inbox")
        addItemButton.tap()

        let urlField = app.textFields["AddInbox.URLField"]
        XCTAssertTrue(urlField.waitForExistence(timeout: 5), "URL field should exist")
        urlField.tap()
        urlField.typeText("https://example.com")

        let titleField = app.textFields["AddInbox.TitleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Title field should exist")
        titleField.tap()
        let uniqueTitle = "UI Test " + UUID().uuidString
        titleField.typeText(uniqueTitle)

        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled")
        saveButton.tap()

        let addedItem = app.staticTexts[uniqueTitle]
        XCTAssertTrue(addedItem.waitForExistence(timeout: 5), "Added item should appear in Inbox list")
        addedItem.tap()

        let detailNavigationBar = app.navigationBars[uniqueTitle]
        XCTAssertTrue(detailNavigationBar.waitForExistence(timeout: 5), "Detail navigation bar should show the item title")

        let openInBrowserButton = app.buttons["ブラウザで開く"]
        XCTAssertTrue(openInBrowserButton.waitForExistence(timeout: 5), "Open in browser button should exist")
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
