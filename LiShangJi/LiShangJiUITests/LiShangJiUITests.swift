//
//  LiShangJiUITests.swift
//  LiShangJiUITests
//
//  Created for LiShangJi UI tests.
//

import XCTest

final class LiShangJiUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 启动测试

    @MainActor
    func testAppLaunches() throws {
        // 验证 App 成功启动，首页导航标题可见
        let navTitle = app.navigationBars["礼小记"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5), "首页导航标题应该可见")
    }

    @MainActor
    func testTabBarHasFourTabs() throws {
        // 验证底部 Tab Bar 包含 4 个 Tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab Bar 应该存在")

        XCTAssertTrue(tabBar.buttons["首页"].exists, "首页 Tab 应该存在")
        XCTAssertTrue(tabBar.buttons["账本"].exists, "账本 Tab 应该存在")
        XCTAssertTrue(tabBar.buttons["统计"].exists, "统计 Tab 应该存在")
        XCTAssertTrue(tabBar.buttons["我的"].exists, "我的 Tab 应该存在")
    }

    // MARK: - Tab 导航测试

    @MainActor
    func testNavigateToBooks() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["账本"].tap()

        let navTitle = app.navigationBars["账本"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "账本导航标题应该可见")
    }

    @MainActor
    func testNavigateToStatistics() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["统计"].tap()

        let navTitle = app.navigationBars["统计分析"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "统计分析导航标题应该可见")
    }

    @MainActor
    func testNavigateToProfile() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["我的"].tap()

        let navTitle = app.navigationBars["我的"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "我的导航标题应该可见")
    }

    @MainActor
    func testNavigateBackToHome() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // 导航到其他 Tab 再返回首页
        tabBar.buttons["账本"].tap()
        tabBar.buttons["首页"].tap()

        let navTitle = app.navigationBars["礼小记"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "回到首页后导航标题应该可见")
    }

    // MARK: - 记录录入流程测试

    @MainActor
    func testFABOpenRecordEntry() throws {
        // 点击 FAB 按钮
        let fab = app.buttons["fab_add_record"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5), "FAB 按钮应该存在")

        fab.tap()

        // 验证录入 Sheet 弹出
        let navTitle = app.navigationBars["新增记录"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "新增记录 Sheet 应该弹出")
    }

    @MainActor
    func testRecordEntryHasDirectionPicker() throws {
        let fab = app.buttons["fab_add_record"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5))
        fab.tap()

        // 验证收到/送出切换存在
        let sheet = app.navigationBars["新增记录"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        // 验证送出和收到按钮存在
        XCTAssertTrue(app.staticTexts["送出"].exists || app.buttons["送出"].exists, "送出按钮应该存在")
        XCTAssertTrue(app.staticTexts["收到"].exists || app.buttons["收到"].exists, "收到按钮应该存在")
    }

    @MainActor
    func testRecordEntryHasAmountDisplay() throws {
        let fab = app.buttons["fab_add_record"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5))
        fab.tap()

        let sheet = app.navigationBars["新增记录"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        // 验证金额显示区域存在（¥ 符号）
        XCTAssertTrue(app.staticTexts["¥"].exists, "¥ 符号应该存在")
    }

    @MainActor
    func testRecordEntryCancelButton() throws {
        let fab = app.buttons["fab_add_record"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5))
        fab.tap()

        let sheet = app.navigationBars["新增记录"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        // 点击取消关闭 Sheet
        let cancelButton = app.buttons["取消"]
        XCTAssertTrue(cancelButton.exists, "取消按钮应该存在")
        cancelButton.tap()

        // 验证 Sheet 关闭
        XCTAssertTrue(app.navigationBars["礼小记"].waitForExistence(timeout: 3), "应该回到首页")
    }

    // MARK: - 账本管理测试

    @MainActor
    func testBooksTabShowsCreateButton() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["账本"].tap()

        let navTitle = app.navigationBars["账本"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        // 验证创建账本按钮存在
        let createButton = app.buttons["create_book_button"]
        XCTAssertTrue(createButton.exists, "创建账本按钮应该存在")
    }

    @MainActor
    func testBooksTabEmptyState() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["账本"].tap()

        // 初始状态可能显示空状态视图或账本列表
        let navTitle = app.navigationBars["账本"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))
    }

    // MARK: - 我的/设置测试

    @MainActor
    func testSettingsShowsContactManagement() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["我的"].tap()

        let navTitle = app.navigationBars["我的"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        // 验证设置项存在
        XCTAssertTrue(app.staticTexts["联系人管理"].exists, "联系人管理应该可见")
    }

    @MainActor
    func testSettingsShowsEventsAndFestivals() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["我的"].tap()

        let navTitle = app.navigationBars["我的"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        XCTAssertTrue(app.staticTexts["事件与节日"].exists, "事件与节日应该可见")
    }

    @MainActor
    func testSettingsShowsExportData() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["我的"].tap()

        let navTitle = app.navigationBars["我的"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        XCTAssertTrue(app.staticTexts["导出数据"].exists, "导出数据应该可见")
    }

    @MainActor
    func testSettingsShowsAbout() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["我的"].tap()

        let navTitle = app.navigationBars["我的"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        XCTAssertTrue(app.staticTexts["关于礼小记"].exists, "关于礼小记应该可见")
    }

    @MainActor
    func testSettingsShowsVersionInfo() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["我的"].tap()

        let navTitle = app.navigationBars["我的"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        XCTAssertTrue(app.staticTexts["礼小记 v1.0"].exists, "版本号应该可见")
    }

    @MainActor
    func testNavigateToContactList() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        tabBar.buttons["我的"].tap()

        let navTitle = app.navigationBars["我的"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))

        // 点击联系人管理
        let contactsButton = app.buttons["settings_contacts"]
        if contactsButton.exists {
            contactsButton.tap()
        } else {
            app.staticTexts["联系人管理"].tap()
        }

        let contactsNavTitle = app.navigationBars["联系人"]
        XCTAssertTrue(contactsNavTitle.waitForExistence(timeout: 3), "联系人页面应该打开")
    }

    // MARK: - 启动性能测试

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
