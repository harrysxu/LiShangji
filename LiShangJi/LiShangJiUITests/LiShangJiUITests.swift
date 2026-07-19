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
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 启动测试

    @MainActor
    func testAppLaunches() throws {
        // 验证 App 成功启动，首页导航标题可见
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 8), "首页应该可见")
    }

    @MainActor
    func testOnboardingLegalDocumentsDoNotImplicitlyConsent() throws {
        app.terminate()
        let onboardingApp = XCUIApplication()
        onboardingApp.launchArguments = ["-ui-testing", "-ui-testing-onboarding"]
        onboardingApp.launch()

        let startButton = onboardingApp.buttons["开始使用"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 8), "首次启动页应该可见")

        onboardingApp.buttons["《用户协议》"].tap()
        XCTAssertTrue(onboardingApp.navigationBars["用户协议"].waitForExistence(timeout: 3))
        XCTAssertTrue(onboardingApp.staticTexts["免责声明"].exists || onboardingApp.staticTexts["服务说明"].exists)
        onboardingApp.navigationBars["用户协议"].buttons["关闭"].tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "关闭协议不应视为同意")

        onboardingApp.buttons["《隐私政策》"].tap()
        XCTAssertTrue(onboardingApp.navigationBars["隐私政策"].waitForExistence(timeout: 3))
        XCTAssertTrue(onboardingApp.staticTexts["数据存储"].exists)
        onboardingApp.navigationBars["隐私政策"].buttons["关闭"].tap()
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "关闭隐私政策不应视为同意")

        startButton.tap()
        XCTAssertTrue(onboardingApp.staticTexts["首页"].waitForExistence(timeout: 8), "明确同意后应进入首页")
    }

    @MainActor
    func testTabBarHasFourTabs() throws {
        // iPhone 使用底部 Tab Bar，iPad 使用侧边栏导航。
        XCTAssertTrue(tabExists("首页"), "首页导航入口应该存在")
        XCTAssertTrue(tabExists("账本"), "账本导航入口应该存在")
        XCTAssertTrue(tabExists("往来"), "往来导航入口应该存在")
        XCTAssertTrue(tabExists("我的"), "我的导航入口应该存在")
    }

    // MARK: - Tab 导航测试

    @MainActor
    func testNavigateToBooks() throws {
        selectTab("账本")

        XCTAssertTrue(app.staticTexts["账本"].waitForExistence(timeout: 3), "账本标题应该可见")
    }

    @MainActor
    func testNavigateToInteractions() throws {
        selectTab("往来")

        XCTAssertTrue(app.navigationBars["往来"].waitForExistence(timeout: 3), "往来标题应该可见")
        XCTAssertTrue(
            app.segmentedControls["interaction_mode_picker"].waitForExistence(timeout: 3),
            "往来页面应该可见"
        )
    }

    @MainActor
    func testInteractionModePickerKeepsStableTopPosition() throws {
        selectTab("往来")

        let picker = app.segmentedControls["interaction_mode_picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 3), "往来分段控件应该可见")
        let initialMinY = picker.frame.minY

        for mode in ["待回礼", "提醒", "联系人"] {
            let segment = picker.buttons[mode]
            XCTAssertTrue(segment.exists, "\(mode)分段应该存在")
            segment.tap()
            XCTAssertEqual(
                picker.frame.minY,
                initialMinY,
                accuracy: 1,
                "切换到\(mode)时顶部位置不应变化"
            )
        }
    }

    @MainActor
    func testNavigateToProfile() throws {
        selectTab("我的")

        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3), "我的标题应该可见")
    }

    @MainActor
    func testNavigateBackToHome() throws {
        // 导航到其他 Tab 再返回首页
        selectTab("账本")
        selectTab("首页")

        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 3), "回到首页后标题应该可见")
    }

    // MARK: - 记录录入流程测试

    @MainActor
    func testFABOpenRecordEntry() throws {
        openManualEntry()

        // 验证录入 Sheet 弹出
        let navTitle = app.navigationBars["新增记录"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3), "新增记录 Sheet 应该弹出")
    }

    @MainActor
    func testRecordEntryHasDirectionPicker() throws {
        openManualEntry()

        // 验证收到/送出切换存在
        let sheet = app.navigationBars["新增记录"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        // 验证送出和收到按钮存在
        XCTAssertTrue(app.staticTexts["送出"].exists || app.buttons["送出"].exists, "送出按钮应该存在")
        XCTAssertTrue(app.staticTexts["收到"].exists || app.buttons["收到"].exists, "收到按钮应该存在")
    }

    @MainActor
    func testRecordEntryHasAmountDisplay() throws {
        openManualEntry()

        let sheet = app.navigationBars["新增记录"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        // 验证金额显示区域存在（¥ 符号）
        XCTAssertTrue(app.staticTexts["¥"].exists, "¥ 符号应该存在")
    }

    @MainActor
    func testRecordEntryCancelButton() throws {
        openManualEntry()

        let sheet = app.navigationBars["新增记录"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))

        // 点击取消关闭 Sheet
        let cancelButton = app.buttons["取消"]
        XCTAssertTrue(cancelButton.exists, "取消按钮应该存在")
        cancelButton.tap()

        // 验证 Sheet 关闭
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 3), "应该回到首页")
    }

    // MARK: - 账本管理测试

    @MainActor
    func testBooksTabShowsCreateButton() throws {
        selectTab("账本")

        XCTAssertTrue(app.staticTexts["账本"].waitForExistence(timeout: 3))

        // 验证创建账本按钮存在
        let createButton = app.buttons["create_book_button"]
        let emptyCreateButton = app.buttons["创建账本"]
        XCTAssertTrue(createButton.exists || emptyCreateButton.exists, "创建账本按钮应该存在")
    }

    @MainActor
    func testBooksTabEmptyState() throws {
        selectTab("账本")

        // 初始状态可能显示空状态视图或账本列表
        XCTAssertTrue(app.staticTexts["账本"].waitForExistence(timeout: 3))
    }

    // MARK: - 我的/设置测试

    @MainActor
    func testSettingsShowsContactManagement() throws {
        selectTab("我的")

        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))

        // 验证设置项存在
        XCTAssertTrue(app.staticTexts["联系人管理"].exists, "联系人管理应该可见")
    }

    @MainActor
    func testSettingsShowsEventsAndFestivals() throws {
        selectTab("我的")

        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))

        XCTAssertTrue(app.staticTexts["事件与节日"].exists, "事件与节日应该可见")
    }

    @MainActor
    func testSettingsShowsExportData() throws {
        selectTab("我的")

        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))

        let exportData = app.staticTexts["导出数据"]
        XCTAssertTrue(revealByScrollingUp(exportData), "导出数据应该可见")
    }

    @MainActor
    func testSettingsShowsAbout() throws {
        selectTab("我的")

        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))

        let about = app.staticTexts["关于礼小记"]
        XCTAssertTrue(revealByScrollingUp(about), "关于礼小记应该可见")
    }

    @MainActor
    func testSettingsShowsVersionInfo() throws {
        selectTab("我的")

        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))

        let version = app.staticTexts["礼小记 v1.2"]
        XCTAssertTrue(revealByScrollingUp(version), "版本号应该可见")
    }

    @MainActor
    func testHelpAndReleaseNotesDocuments() throws {
        selectTab("我的")

        let help = app.staticTexts["帮助与更新说明"]
        XCTAssertTrue(revealByScrollingUp(help), "帮助入口应该可见")
        help.tap()

        XCTAssertTrue(app.navigationBars["帮助与更新说明"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["1.2 更新说明"].exists)
        XCTAssertTrue(app.staticTexts["使用边界"].exists)
        let purchaseSection = app.staticTexts["购买与恢复"]
        XCTAssertTrue(revealByScrollingUp(purchaseSection))
        let buyout = app.staticTexts["一次性买断"]
        XCTAssertTrue(revealByScrollingUp(buyout))
    }

    @MainActor
    func testAboutShowsBundleVersionAndBuild() throws {
        selectTab("我的")

        let about = app.staticTexts["关于礼小记"]
        XCTAssertTrue(revealByScrollingUp(about))
        about.tap()

        XCTAssertTrue(app.navigationBars["关于"].waitForExistence(timeout: 3))
        let version = app.staticTexts.containing(
            NSPredicate(format: "label BEGINSWITH '版本 1.2 ('")
        ).firstMatch
        XCTAssertTrue(revealByScrollingUp(version), "关于页应展示 Bundle 中的版本和 build")
    }

    @MainActor
    func testNavigateToContactList() throws {
        selectTab("我的")

        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))

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

    @MainActor
    func testPremiumGateOpensPurchaseSheet() throws {
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 8))

        let scanButton = app.buttons["扫一扫"].firstMatch
        XCTAssertTrue(scanButton.waitForExistence(timeout: 5), "免费态首页应该展示扫一扫入口")
        scanButton.tap()

        XCTAssertTrue(app.staticTexts["礼小记 高级版"].waitForExistence(timeout: 5), "免费态点击 OCR 应打开高级版购买页")
        XCTAssertTrue(app.staticTexts["OCR 扫描识别"].exists, "购买页应说明 OCR 权益")
        XCTAssertTrue(app.staticTexts["语音记账"].exists, "购买页应说明语音权益")
        XCTAssertTrue(app.buttons["恢复购买"].exists || app.staticTexts["恢复购买"].exists, "购买页应提供恢复购买")
        XCTAssertTrue(
            app.buttons["立即购买"].exists
                || app.staticTexts["正在加载产品信息..."].exists
                || app.staticTexts.containing(NSPredicate(format: "label CONTAINS '¥' OR label CONTAINS '$'")).firstMatch.exists,
            "购买页应展示购买按钮、价格或产品加载状态"
        )
    }

    @MainActor
    func testVoiceRecordingCanBeStoppedOnDevice() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("语音采集结束流程需要真实麦克风和设备端语音识别")
        #else
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-premium"]
        app.launch()

        let voiceButton = app.buttons["home_voice_input"]
        XCTAssertTrue(voiceButton.waitForExistence(timeout: 8), "首页语音入口应该可见")
        voiceButton.tap()

        let stopButton = app.buttons["voice_stop_button"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 8), "录音开始后应该展示明确的结束按钮")
        stopButton.tap()
        XCTAssertTrue(
            waitUntilGone(stopButton, timeout: 5),
            "点击结束后录音遮罩应该消失"
        )
        #endif
    }

    @MainActor
    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !element.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return !element.exists
    }

    @MainActor
    func testPurchaseLegalDisclosureAndDocuments() throws {
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 8))
        app.buttons["扫一扫"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["礼小记 高级版"].waitForExistence(timeout: 5))

        let disclosure = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS '无订阅，无自动续费'")
        ).firstMatch
        XCTAssertTrue(revealByScrollingUp(disclosure), "购买页应明确非订阅且无自动续费")

        let agreement = app.buttons["《用户协议》"]
        XCTAssertTrue(revealByScrollingUp(agreement), "用户协议入口应该可点击")
        agreement.tap()
        XCTAssertTrue(app.navigationBars["用户协议"].waitForExistence(timeout: 5))
        tapBackButton(navigationTitle: "用户协议")

        let privacy = app.buttons["《隐私政策》"]
        XCTAssertTrue(revealByScrollingUp(privacy))
        privacy.tap()
        XCTAssertTrue(app.navigationBars["隐私政策"].waitForExistence(timeout: 3))
        tapBackButton(navigationTitle: "隐私政策")
        XCTAssertTrue(app.buttons["恢复购买"].waitForExistence(timeout: 3), "法律文档返回后购买页应保持可用")
    }

    @MainActor
    func testDataSafetyEntryShowsBackupRestoreAndCSV() throws {
        selectTab("我的")

        let dataSafety = app.staticTexts["备份、恢复与导入"].firstMatch
        XCTAssertTrue(revealByScrollingUp(dataSafety), "数据管理入口应该可见")
        dataSafety.tap()

        XCTAssertTrue(app.navigationBars["数据管理"].waitForExistence(timeout: 3), "数据管理页应该打开")
        XCTAssertTrue(app.staticTexts["当前数据"].exists, "应展示当前数据摘要")
        XCTAssertTrue(app.buttons["创建可恢复备份"].exists, "应展示备份入口")
        XCTAssertTrue(app.buttons["从备份恢复"].exists, "应展示恢复入口")
        XCTAssertTrue(app.buttons["导入 CSV"].exists, "应展示 CSV 导入入口")
        XCTAssertTrue(app.buttons["导出 CSV"].exists, "应展示 CSV 导出入口")
    }

    @MainActor
    func testClearDataDisclosureMentionsRecoveryPoint() throws {
        selectTab("我的")

        let clearData = app.staticTexts["清空数据"]
        XCTAssertTrue(revealByScrollingUp(clearData))
        clearData.tap()

        XCTAssertTrue(app.navigationBars["清空数据"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts["删除前会自动创建本机恢复点。请确认完整备份已妥善保存。"].exists,
            "清空前应说明恢复点和备份"
        )
    }

    @MainActor
    func testProductSurfaceSnapshotFlow() throws {
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 8))
        attachScreenshot(named: "product-home")

        app.buttons["新增"].firstMatch.tap()
        XCTAssertTrue(app.buttons["手动记一笔"].waitForExistence(timeout: 2), "新增菜单应该展开")
        attachScreenshot(named: "product-global-add-menu")
        app.buttons["手动记一笔"].tap()
        XCTAssertTrue(app.navigationBars["新增记录"].waitForExistence(timeout: 3), "新增记录页应该打开")
        attachScreenshot(named: "product-record-entry")
        app.buttons["取消"].tap()

        selectTab("我的")
        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))
        attachScreenshot(named: "product-settings")

        let dataSafety = app.staticTexts["备份、恢复与导入"].firstMatch
        XCTAssertTrue(revealByScrollingUp(dataSafety), "数据管理入口应该可见")
        dataSafety.tap()
        XCTAssertTrue(app.navigationBars["数据管理"].waitForExistence(timeout: 3))
        attachScreenshot(named: "product-data-safety")
        let dataNavigationBar = app.navigationBars["数据管理"]
        let backButton = dataNavigationBar.buttons
            .matching(NSPredicate(format: "identifier != 'ToggleSidebar'"))
            .firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 2), "数据管理页返回按钮应该存在")
        backButton.tap()
        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3), "应该返回我的页面")

        let upgrade = app.staticTexts["升级高级版"].firstMatch
        XCTAssertTrue(revealByScrollingDown(upgrade), "升级高级版入口应该可见")
        upgrade.tap()
        XCTAssertTrue(app.staticTexts["礼小记 高级版"].waitForExistence(timeout: 5))
        attachScreenshot(named: "product-purchase")
    }

    @MainActor
    func testLandscapeSettingsCriticalEntriesRemainReachable() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        selectTab("我的")
        XCTAssertTrue(app.staticTexts["我的"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            revealByScrollingUp(app.buttons["备份、恢复与导入"].firstMatch),
            "横屏下数据管理入口应该可达"
        )
        XCTAssertTrue(
            revealByScrollingUp(app.buttons["settings_export"].firstMatch),
            "横屏下导出入口应该可达"
        )
        XCTAssertTrue(
            revealByScrollingUp(app.buttons["settings_help_release_notes"].firstMatch),
            "横屏下帮助入口应该可达"
        )
    }

    // MARK: - 启动性能测试

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testHomeVisualSnapshot() throws {
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 8))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "home-visual-snapshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func openManualEntry() {
        let addButton = app.buttons["新增"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "新增菜单应该存在")
        addButton.tap()
        let manual = app.buttons["手动记一笔"]
        XCTAssertTrue(manual.waitForExistence(timeout: 2))
        manual.tap()
    }

    @MainActor
    private func selectTab(_ title: String) {
        let tabBarButton = app.tabBars.buttons[title].firstMatch
        if tabBarButton.waitForExistence(timeout: 2) {
            tabBarButton.tap()
            return
        }

        let sidebarButton = app.buttons[title].firstMatch
        XCTAssertTrue(sidebarButton.waitForExistence(timeout: 5), "\(title) 导航入口应该存在")
        sidebarButton.tap()
    }

    @MainActor
    private func tabExists(_ title: String) -> Bool {
        if app.tabBars.buttons[title].firstMatch.waitForExistence(timeout: 2) {
            return true
        }
        return app.buttons[title].firstMatch.waitForExistence(timeout: 2)
    }

    @MainActor
    private func tapBackButton(navigationTitle: String) {
        let navigationBar = app.navigationBars[navigationTitle]
        for label in ["Back", "返回", "升级高级版"] {
            let button = navigationBar.buttons[label]
            if button.exists {
                button.tap()
                return
            }
        }
        let fallback = navigationBar.buttons
            .matching(NSPredicate(format: "identifier != 'ToggleSidebar'"))
            .firstMatch
        XCTAssertTrue(fallback.waitForExistence(timeout: 2), "\(navigationTitle) 返回按钮应该存在")
        fallback.tap()
    }

    @MainActor
    private func revealByScrollingUp(_ element: XCUIElement, maxSwipes: Int = 32) -> Bool {
        if element.waitForExistence(timeout: 0.5), element.isHittable {
            return true
        }

        for _ in 0..<maxSwipes {
            dragList(up: true)
            if element.waitForExistence(timeout: 0.75), element.isHittable {
                return true
            }
        }

        return element.exists && element.isHittable
    }

    @MainActor
    private func revealByScrollingDown(_ element: XCUIElement, maxSwipes: Int = 32) -> Bool {
        if element.waitForExistence(timeout: 0.5), element.isHittable {
            return true
        }

        for _ in 0..<maxSwipes {
            dragList(up: false)
            if element.waitForExistence(timeout: 0.75), element.isHittable {
                return true
            }
        }

        return element.exists && element.isHittable
    }

    @MainActor
    private func dragList(up: Bool) {
        let collectionView = app.collectionViews.firstMatch
        let scrollView = app.scrollViews.firstMatch
        let surface: XCUIElement
        if collectionView.exists {
            surface = collectionView
        } else if scrollView.exists {
            surface = scrollView
        } else {
            surface = app!
        }
        let start = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.70 : 0.50))
        let end = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.50 : 0.70))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// Runs against the installed app without UI-test entitlement overrides so the
/// persisted upgrade container and purchased feature set are exercised.
final class LiShangJiRealDeviceCRUDUITests: XCTestCase {
    private var app: XCUIApplication!
    private let contactName = "真机回归联系人0719"
    private let bookName = "真机回归账本0719"
    private let editedBookName = "真机回归账本0719改"
    private let eventTitle = "真机回归提醒0719"

    override func setUpWithError() throws {
        continueAfterFailure = false
#if targetEnvironment(simulator)
        throw XCTSkip("仅在已安装并预置数据的真机上运行")
#endif
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30), "真实安装态 App 应进入前台")
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 30), "真实安装态应进入首页")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testInstalledUpgradeContainerCRUDAndAggregates() throws {
        try createAndEditContact()
        try createAndEditBook()
        try createRecordAndVerifyReciprocity()
        try createEditCompleteAndDeleteReminder()
        try editAndDeleteRecord()
        try deleteBookAndContact()
    }

    @MainActor
    func testEventFormAccessibilitySurface() throws {
        selectTab("往来")
        app.segmentedControls["interaction_mode_picker"].buttons["提醒"].tap()
        app.buttons["添加提醒"].tap()
        XCTAssertTrue(app.navigationBars["新建事件"].waitForExistence(timeout: 5))
        let reminderLabel = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS '提醒设置'"))
            .firstMatch
        XCTAssertTrue(reminderLabel.exists, "提醒设置区应出现在可访问性树")
        XCTAssertTrue(labeled("事件发生时").exists, "提醒选项应出现在可访问性树")
        XCTAssertTrue(labeled("去选择").exists, "关联联系人入口应出现在可访问性树")
    }

    @MainActor
    func testICloudConfigurationStagesBackupAndCanBeReverted() throws {
        selectTab("我的")
        let entry = app.staticTexts["iCloud 同步"].firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "iCloud 设置入口应存在")
        entry.tap()
        XCTAssertTrue(app.navigationBars["iCloud 同步"].waitForExistence(timeout: 5))

        let toggles = app.switches
            .matching(NSPredicate(format: "label CONTAINS 'iCloud 同步'"))
        // SwiftUI exposes the row and its nested native control as two AX switches.
        // Tapping the nested element can be a no-op on a physical device, while
        // the trailing coordinate of the row consistently invokes the Binding.
        let toggle = toggles.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "iCloud 开关应存在")
        if toggle.value as? String == "0" || toggle.value as? String == "关闭" {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            let enableAlert = app.alerts["开启 iCloud 同步"].firstMatch
            if !enableAlert.waitForExistence(timeout: 5) {
                add(XCTAttachment(string: app.debugDescription))
            }
            XCTAssertTrue(enableAlert.waitForExistence(timeout: 5))
            enableAlert.buttons["创建备份并开启"].tap()
            let configAlert = app.alerts["iCloud 配置"].firstMatch
            XCTAssertTrue(configAlert.waitForExistence(timeout: 5))
            configAlert.buttons["确定"].tap()
        }

        XCTAssertTrue(
            app.staticTexts["配置待生效，请重新打开 App"].waitForExistence(timeout: 5)
                || app.staticTexts["将在下次启动时开启"].waitForExistence(timeout: 5),
            "开启 iCloud 后应明确提示重启生效"
        )

        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let disableAlert = app.alerts["关闭 iCloud 同步"].firstMatch
        if !disableAlert.waitForExistence(timeout: 5) {
            add(XCTAttachment(string: app.debugDescription))
        }
        XCTAssertTrue(disableAlert.waitForExistence(timeout: 5))
        disableAlert.buttons["创建备份并关闭"].tap()
        let disableConfigAlert = app.alerts["iCloud 配置"].firstMatch
        XCTAssertTrue(disableConfigAlert.waitForExistence(timeout: 5))
        disableConfigAlert.buttons["确定"].tap()
        XCTAssertTrue(app.staticTexts["将在下次启动时关闭"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        XCTAssertTrue(app.staticTexts["首页"].waitForExistence(timeout: 10), "关闭 iCloud 后重启应回到首页")
    }

    @MainActor
    private func createAndEditContact() throws {
        selectTab("我的")
        let contacts = app.buttons["settings_contacts"].firstMatch
        if contacts.waitForExistence(timeout: 2) {
            contacts.tap()
        } else {
            app.staticTexts["联系人管理"].tap()
        }
        XCTAssertTrue(app.navigationBars["联系人"].waitForExistence(timeout: 5))
        let listSearch = app.textFields["搜索联系人"]
        listSearch.tap()
        listSearch.typeText(contactName)
        let existing = app.staticTexts[contactName]
        if existing.waitForExistence(timeout: 2) {
            existing.swipeLeft()
            app.buttons["删除"].tap()
            XCTAssertTrue(waitUntilGone(existing, timeout: 5), "上次未完成的测试联系人应先清理")
        }

        app.buttons["添加联系人"].tap()
        XCTAssertTrue(app.navigationBars["添加联系人"].waitForExistence(timeout: 5))
        app.textFields["姓名"].tap()
        app.textFields["姓名"].typeText(contactName)
        app.navigationBars["添加联系人"].buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts[contactName].waitForExistence(timeout: 5), "联系人应创建成功")

        app.staticTexts[contactName].tap()
        XCTAssertTrue(app.navigationBars[contactName].waitForExistence(timeout: 5))
        app.buttons["联系人更多操作"].tap()
        app.buttons["编辑"].tap()
        XCTAssertTrue(app.navigationBars["编辑联系人"].waitForExistence(timeout: 5))
        let phone = app.textFields["电话（选填）"]
        phone.tap()
        phone.typeText("13800138071")
        app.navigationBars["编辑联系人"].buttons["保存"].tap()
        dismissKeyboard()
        XCTAssertTrue(app.staticTexts["13800138071"].waitForExistence(timeout: 5), "联系人编辑结果应展示")
        tapBack(navigationTitle: contactName)
    }

    @MainActor
    private func createAndEditBook() throws {
        selectTab("账本")
        removeBookIfPresent(editedBookName)
        removeBookIfPresent(bookName)
        app.buttons["create_book_button"].tap()
        XCTAssertTrue(
            app.navigationBars["新建账本"].waitForExistence(timeout: 5),
            "真实已购状态应允许新建第八个账本"
        )
        let nameField = app.textFields["例如：我的婚礼、2026春节"]
        nameField.tap()
        nameField.typeText(bookName)
        app.navigationBars["新建账本"].buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts[bookName].waitForExistence(timeout: 5), "账本应创建成功")

        app.staticTexts[bookName].tap()
        XCTAssertTrue(app.navigationBars[bookName].waitForExistence(timeout: 5))
        app.buttons["账本更多操作"].tap()
        app.buttons["编辑账本"].tap()
        XCTAssertTrue(app.navigationBars["编辑账本"].waitForExistence(timeout: 5))
        let editName = app.textFields["例如：我的婚礼、2026春节"]
        editName.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        editName.typeText("改")
        app.navigationBars["编辑账本"].buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars[editedBookName].waitForExistence(timeout: 5), "账本编辑应即时生效")
    }

    @MainActor
    private func createRecordAndVerifyReciprocity() throws {
        app.buttons.matching(identifier: "添加记录").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["新增记录"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label == '收到'")).firstMatch.tap()
        app.buttons["contact_picker_button"].tap()
        XCTAssertTrue(app.navigationBars["选择联系人"].waitForExistence(timeout: 5))
        let search = app.textFields["搜索联系人"]
        search.tap()
        search.typeText(contactName)
        XCTAssertTrue(app.staticTexts[contactName].waitForExistence(timeout: 5))
        app.staticTexts[contactName].tap()

        let quickAmount = app.buttons["888"].firstMatch
        XCTAssertTrue(quickAmount.waitForExistence(timeout: 5))
        quickAmount.tap()
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars[editedBookName].waitForExistence(timeout: 6), "保存记录后应返回账本")
        XCTAssertTrue(textContaining("888").waitForExistence(timeout: 5), "账本汇总应包含新金额")

        selectTab("往来")
        let picker = app.segmentedControls["interaction_mode_picker"]
        picker.buttons["联系人"].tap()
        let contactSearch = app.textFields["搜索联系人"]
        contactSearch.tap()
        contactSearch.typeText(contactName)
        app.staticTexts[contactName].tap()
        XCTAssertTrue(app.navigationBars[contactName].waitForExistence(timeout: 5))
        XCTAssertTrue(textContaining("888").waitForExistence(timeout: 5), "联系人聚合应包含新记录")
        let addReturn = app.buttons["加入待回礼"]
        XCTAssertTrue(addReturn.waitForExistence(timeout: 5), "收到记录应支持加入待回礼")
        addReturn.tap()
        XCTAssertTrue(app.buttons["按此记录回礼"].waitForExistence(timeout: 5))
        tapBack(navigationTitle: contactName)

        picker.buttons["待回礼"].tap()
        XCTAssertTrue(app.staticTexts[contactName].waitForExistence(timeout: 5), "待回礼列表应出现该记录")
        app.buttons["无需回礼"].tap()
        XCTAssertTrue(waitUntilGone(app.staticTexts[contactName], timeout: 5), "无需回礼后应移出列表")
    }

    @MainActor
    private func createEditCompleteAndDeleteReminder() throws {
        let picker = app.segmentedControls["interaction_mode_picker"]
        picker.buttons["提醒"].tap()
        removeReminderIfPresent(named: eventTitle)
        app.buttons["添加提醒"].tap()
        XCTAssertTrue(app.navigationBars["新建事件"].waitForExistence(timeout: 5))
        let title = app.textFields["输入事件标题，如「张三婚礼」"]
        title.tap()
        title.typeText(eventTitle)

        let atTime = labeled("事件发生时")
        XCTAssertTrue(atTime.waitForExistence(timeout: 5), "提醒选项应出现在表单")
        atTime.tap()

        let chooseContact = labeled("去选择")
        XCTAssertTrue(chooseContact.waitForExistence(timeout: 5), "关联联系人入口应可达")
        chooseContact.tap()
        XCTAssertTrue(app.navigationBars["选择联系人"].waitForExistence(timeout: 5))
        let search = app.textFields["搜索联系人"]
        search.tap()
        search.typeText(contactName)
        app.staticTexts[contactName].tap()
        app.navigationBars["选择联系人"].buttons["完成"].tap()

        let note = app.textFields["添加备注..."]
        XCTAssertTrue(note.waitForExistence(timeout: 5), "提醒备注应可编辑")
        note.tap()
        note.typeText("真机回归提醒备注")

        addUIInterruptionMonitor(withDescription: "通知权限") { alert in
            let allow = alert.buttons.matching(NSPredicate(format: "label CONTAINS '允许'")).firstMatch
            if allow.exists {
                allow.tap()
                return true
            }
            return false
        }
        app.navigationBars["新建事件"].buttons["保存"].tap()
        app.tap()
        XCTAssertTrue(app.staticTexts[eventTitle].waitForExistence(timeout: 8), "提醒应创建成功")
        app.staticTexts[eventTitle].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["事件详情"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[contactName].exists, "提醒应保留联系人关联")
        XCTAssertTrue(app.staticTexts["事件发生时"].exists, "提醒设置应保存")
        XCTAssertTrue(app.staticTexts["真机回归提醒备注"].exists, "提醒备注应保存")

        app.buttons["编辑"].tap()
        XCTAssertTrue(app.navigationBars["编辑事件"].waitForExistence(timeout: 5))
        let noReminder = labeled("不提醒")
        XCTAssertTrue(noReminder.waitForExistence(timeout: 5))
        noReminder.tap()
        app.navigationBars["编辑事件"].buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["事件详情"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["不提醒"].exists, "编辑后的提醒设置应生效")

        let complete = app.buttons["标记为已完成"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        complete.tap()
        XCTAssertTrue(app.staticTexts["已完成"].waitForExistence(timeout: 5))
        let reopen = app.buttons["标记为未完成"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 5))
        reopen.tap()

        let delete = app.buttons["删除事件"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        app.alerts["确认删除"].buttons["删除"].tap()
        XCTAssertTrue(waitUntilGone(app.staticTexts[eventTitle], timeout: 5), "提醒应从列表删除")
    }

    @MainActor
    private func editAndDeleteRecord() throws {
        selectTab("账本")
        app.staticTexts[editedBookName].tap()
        XCTAssertTrue(app.navigationBars[editedBookName].waitForExistence(timeout: 5))
        app.staticTexts[contactName].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["记录详情"].waitForExistence(timeout: 5))
        app.buttons["记录更多操作"].tap()
        app.buttons["编辑"].tap()
        XCTAssertTrue(app.navigationBars["编辑记录"].waitForExistence(timeout: 5))
        let amount = app.textFields["record_edit_amount_field"]
        amount.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        amount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        amount.typeText("999")
        app.buttons["送出"].tap()
        let note = app.textFields["备注（选填）"]
        note.tap()
        note.typeText("真机回归记录备注")
        app.navigationBars["编辑记录"].buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["记录详情"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["送出"].exists)
        XCTAssertTrue(textContaining("999").exists, "编辑后的金额应展示")
        XCTAssertTrue(app.staticTexts["真机回归记录备注"].exists)

        app.buttons["记录更多操作"].tap()
        app.buttons["删除"].tap()
        app.buttons["删除此记录"].tap()
        XCTAssertTrue(app.navigationBars[editedBookName].waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntilGone(app.staticTexts[contactName], timeout: 5), "删除后账本中不应保留测试记录")
    }

    @MainActor
    private func deleteBookAndContact() throws {
        tapBack(navigationTitle: editedBookName)
        let book = app.staticTexts[editedBookName]
        XCTAssertTrue(book.waitForExistence(timeout: 5))
        book.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["删除"].waitForExistence(timeout: 5))
        app.buttons["删除"].tap()
        let confirm = app.buttons["删除「\(editedBookName)」及其所有记录"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(waitUntilGone(app.staticTexts[editedBookName], timeout: 5), "测试账本应清理")

        selectTab("往来")
        let picker = app.segmentedControls["interaction_mode_picker"]
        picker.buttons["联系人"].tap()
        let search = app.textFields["搜索联系人"]
        search.tap()
        search.typeText(contactName)
        let row = app.staticTexts[contactName]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        app.buttons["删除"].tap()
        XCTAssertTrue(waitUntilGone(row, timeout: 5), "测试联系人应清理")
    }

    @MainActor
    private func selectTab(_ title: String) {
        dismissKeyboard()
        let button = app.tabBars.buttons[title].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(title) Tab 应存在")
        button.tap()
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(title) Tab 点击后仍应存在")
    }

    @MainActor
    private func tapBack(navigationTitle: String) {
        let bar = app.navigationBars[navigationTitle]
        let back = bar.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5), "\(navigationTitle) 返回按钮应存在")
        back.tap()
    }

    @MainActor
    private func textContaining(_ fragment: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
    }

    @MainActor
    private func labeled(_ text: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", text))
            .firstMatch
    }

    @MainActor
    private func reveal(_ element: XCUIElement, maxSwipes: Int = 20) -> Bool {
        if element.waitForExistence(timeout: 0.5), element.isHittable { return true }
        for _ in 0..<maxSwipes {
            app.scrollViews.firstMatch.swipeUp()
            if element.waitForExistence(timeout: 0.5), element.isHittable { return true }
        }
        return element.exists && element.isHittable
    }

    @MainActor
    private func waitUntilGone(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !element.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return !element.exists
    }

    @MainActor
    private func dismissKeyboard() {
        guard app.keyboards.firstMatch.exists else { return }
        for label in ["完成", "Done", "换行"] {
            let button = app.keyboards.buttons[label].firstMatch
            if button.exists {
                button.tap()
                return
            }
        }
        app.tap()
    }

    @MainActor
    private func removeBookIfPresent(_ name: String) {
        let card = app.staticTexts[name]
        guard card.waitForExistence(timeout: 1) else { return }
        card.press(forDuration: 1.2)
        let delete = app.buttons["删除"]
        guard delete.waitForExistence(timeout: 3) else { return }
        delete.tap()
        let confirm = app.buttons["删除「\(name)」及其所有记录"]
        if confirm.waitForExistence(timeout: 3) {
            confirm.tap()
            _ = waitUntilGone(card, timeout: 5)
        }
    }

    @MainActor
    private func removeReminderIfPresent(named name: String) {
        let existing = app.staticTexts[name].firstMatch
        guard existing.waitForExistence(timeout: 1) else { return }
        existing.tap()
        guard app.navigationBars["事件详情"].waitForExistence(timeout: 5) else { return }
        let delete = app.buttons["删除事件"]
        guard delete.waitForExistence(timeout: 5) else { return }
        delete.tap()
        app.alerts["确认删除"].buttons["删除"].tap()
        _ = waitUntilGone(app.staticTexts[name], timeout: 5)
    }
}
