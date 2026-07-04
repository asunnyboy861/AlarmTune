//
//  M7M8UITests.swift
//  AlarmTuneUITests
//
//  M7a/M8.1/M8.2/M8.3 功能 UI 测试
//

import XCTest

final class M7M8UITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - M7a: Premium 订阅

    /// 测试 Settings 页面 Premium 升级入口
    @MainActor
    func testSettingsPremiumUpgradeEntry() throws {
        let app = XCUIApplication()
        app.launch()

        // 导航到 Settings
        navigateToSettings(app)

        // 免费用户应看到 "Upgrade to Premium" 按钮（section header "Premium" 可能不可直接访问）
        let upgradeText = app.staticTexts["Upgrade to Premium"]
        XCTAssertTrue(upgradeText.waitForExistence(timeout: 5), "Upgrade to Premium should be visible for free users")

        // 验证权益描述存在
        let benefitDesc = app.staticTexts["Unlimited imports & tone generation"]
        XCTAssertTrue(benefitDesc.waitForExistence(timeout: 3), "Benefit description should be visible")
    }

    /// 测试 Paywall 页面展示
    @MainActor
    func testPaywallDisplays() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToSettings(app)

        // 点击 Upgrade to Premium
        let upgradeText = app.staticTexts["Upgrade to Premium"]
        upgradeText.tap()

        // 验证 Paywall 出现
        let paywallTitle = app.staticTexts["Unlock Premium"]
        XCTAssertTrue(paywallTitle.waitForExistence(timeout: 5), "Paywall should display with header")

        // 验证权益列表
        let benefit1 = app.staticTexts["Unlimited Sound Imports"]
        XCTAssertTrue(benefit1.waitForExistence(timeout: 3), "Benefit 'Unlimited Sound Imports' should be visible")

        let benefit2 = app.staticTexts["Unlimited Video Backgrounds"]
        XCTAssertTrue(benefit2.waitForExistence(timeout: 3), "Benefit 'Unlimited Video Backgrounds' should be visible")

        // 验证恢复购买按钮
        let restoreButton = app.buttons["Restore Purchases"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 3), "Restore Purchases button should exist")

        // 关闭 Paywall
        let closeButton = app.buttons["Close"]
        if closeButton.waitForExistence(timeout: 2) {
            closeButton.tap()
        }
    }

    // MARK: - M8.1: Sound Shuffle

    /// 测试 Settings 页面 Sound Shuffle 选项
    @MainActor
    func testSoundShuffleOptions() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToSettings(app)

        // 滚动找到 Shuffle 选项（"Change Daily" 是 Shuffle 区域的选项文本，非 section header）
        let dailyText = app.staticTexts["Change Daily"]
        var attempts = 0
        while !dailyText.exists && attempts < 8 {
            swipeDownInForm(app)
            attempts += 1
        }
        XCTAssertTrue(dailyText.waitForExistence(timeout: 3), "Change Daily option should exist after scrolling")

        // 验证其他选项存在
        let offText = app.staticTexts["Off"]
        XCTAssertTrue(offText.waitForExistence(timeout: 3), "Off option should exist")

        let weeklyText = app.staticTexts["Change Weekly"]
        XCTAssertTrue(weeklyText.waitForExistence(timeout: 3), "Change Weekly option should exist")
    }

    // MARK: - M8.2: Video Background

    /// 测试 Alarm Edit 页面 Video Background section 存在
    @MainActor
    func testAlarmEditVideoBackgroundSection() throws {
        let app = XCUIApplication()
        app.launch()

        // 导航到 Add Alarm
        navigateToAddAlarm(app)

        // 滚动找到 Video Background section（可能需要多次滚动）
        let videoButton = app.buttons["videoPickerButton"]
        var attempts = 0
        while !videoButton.exists && attempts < 5 {
            swipeDownInForm(app)
            attempts += 1
        }
        XCTAssertTrue(videoButton.waitForExistence(timeout: 5), "Video Background button should exist in alarm edit")

        // 验证默认显示 "None"
        XCTAssertTrue(
            videoButton.label.contains("None"),
            "Video Background should default to 'None', got: \(videoButton.label)"
        )
    }

    /// 测试 Video Background Picker 打开和关闭
    @MainActor
    func testVideoBackgroundPickerOpens() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToAddAlarm(app)

        // 滚动找到并点击 Video Background
        let videoButton = app.buttons["videoPickerButton"]
        var attempts = 0
        while !videoButton.exists && attempts < 5 {
            swipeDownInForm(app)
            attempts += 1
        }
        XCTAssertTrue(videoButton.waitForExistence(timeout: 3), "Video Background button should exist")
        videoButton.tap()

        // 验证 Video Background Picker 出现
        let navBar = app.navigationBars["Video Background"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Video Background picker should appear")

        // 验证 "No Video Background" 选项
        let noBackground = app.buttons["No Video Background"]
        XCTAssertTrue(noBackground.waitForExistence(timeout: 3), "No Video Background option should exist")

        // 验证 Built-in Videos 区域
        let builtInText = app.staticTexts["Built-in Videos"]
        XCTAssertTrue(builtInText.waitForExistence(timeout: 3), "Built-in Videos section should exist")

        // 验证 My Videos 区域
        let myVideosText = app.staticTexts["My Videos"]
        XCTAssertTrue(myVideosText.waitForExistence(timeout: 3), "My Videos section should exist")
    }

    /// 测试选择内置视频背景
    @MainActor
    func testSelectBuiltInVideoBackground() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToAddAlarm(app)

        // 打开 Video Background Picker
        let videoButton = app.buttons["videoPickerButton"]
        var attempts = 0
        while !videoButton.exists && attempts < 5 {
            swipeDownInForm(app)
            attempts += 1
        }
        XCTAssertTrue(videoButton.waitForExistence(timeout: 3), "Video Background button should exist")
        videoButton.tap()

        // 等待 picker 出现
        let navBar = app.navigationBars["Video Background"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Video Background picker should appear")

        // 点击第一个内置视频卡片（Sunrise）
        let sunriseText = app.staticTexts["Sunrise"]
        XCTAssertTrue(sunriseText.waitForExistence(timeout: 3), "Sunrise video should exist")
        sunriseText.tap()

        // 验证返回 Alarm Edit 后 Video Background 行显示 "Sunrise"
        let updatedVideoButton = app.buttons["videoPickerButton"]
        XCTAssertTrue(updatedVideoButton.waitForExistence(timeout: 5), "Should return to alarm edit")
        XCTAssertTrue(
            updatedVideoButton.label.contains("Sunrise"),
            "Video Background should show 'Sunrise', got: \(updatedVideoButton.label)"
        )
    }

    // MARK: - M8.3: AI Sound Generation

    /// 测试 Sound Picker 中 AI Generator 入口存在
    @MainActor
    func testSoundPickerAIGeneratorEntry() throws {
        let app = XCUIApplication()
        app.launch()

        // 导航到 Sound Picker
        navigateToSoundPicker(app)

        // 验证 "Generate Tone" 或 "Upgrade for Tone Generator" 按钮存在
        let aiButton = app.staticTexts["Generate Tone"]
        let upgradeAI = app.staticTexts["Upgrade for Tone Generator"]
        let aiExists = aiButton.waitForExistence(timeout: 3)
        let upgradeExists = upgradeAI.waitForExistence(timeout: 3)

        XCTAssertTrue(aiExists || upgradeExists, "Tone Generator entry should exist (either available or locked)")
    }

    /// 测试 AI Generator 页面打开
    @MainActor
    func testAIGeneratorOpens() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToSoundPicker(app)

        // 点击 Generate Tone（如果存在）
        let aiButton = app.staticTexts["Generate Tone"]
        guard aiButton.waitForExistence(timeout: 3) else {
            // 如果是 Upgrade 按钮，说明配额已满，测试通过
            let upgradeAI = app.staticTexts["Upgrade for Tone Generator"]
            XCTAssertTrue(upgradeAI.waitForExistence(timeout: 2), "Should show either tone button or upgrade")
            return
        }

        aiButton.tap()

        // 验证 Tone Generator 页面出现
        let title = app.navigationBars["Tone Generator"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Tone Generator page should appear")

        // 验证风格选项存在
        let calmText = app.staticTexts["Calm"]
        XCTAssertTrue(calmText.waitForExistence(timeout: 3), "Calm style should exist")

        let energeticText = app.staticTexts["Energetic"]
        XCTAssertTrue(energeticText.waitForExistence(timeout: 3), "Energetic style should exist")

        // 验证 Generate 按钮存在
        let generateButton = app.buttons["Generate Sound"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 3), "Generate Sound button should exist")
    }

    // MARK: - Helper Methods

    @MainActor
    private func navigateToSettings(_ app: XCUIApplication) {
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist on alarm list")
        settingsButton.tap()

        // 等待 Settings 页面出现
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Settings page should appear")
    }

    @MainActor
    private func navigateToAddAlarm(_ app: XCUIApplication) {
        let emptyAddButton = app.buttons["addAlarmEmptyButton"]
        let toolbarAddButton = app.buttons["addAlarmToolbarButton"]

        let emptyExists = emptyAddButton.waitForExistence(timeout: 3)
        let toolbarExists = toolbarAddButton.waitForExistence(timeout: 1)

        if emptyExists {
            emptyAddButton.tap()
        } else if toolbarExists {
            toolbarAddButton.tap()
        } else {
            XCTFail("Neither empty-state nor toolbar add button found")
            return
        }

        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 5) else {
            XCTFail("AlarmEditView did not appear")
            return
        }
    }

    @MainActor
    private func navigateToSoundPicker(_ app: XCUIApplication) {
        navigateToAddAlarm(app)

        let soundButton = app.buttons["soundPickerButton"]
        var attempts = 0
        while !soundButton.exists && attempts < 5 {
            swipeDownInForm(app)
            attempts += 1
        }

        if soundButton.waitForExistence(timeout: 3) {
            soundButton.tap()
        } else {
            // 兜底：用谓词查找
            let predicateButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Sound'")
            ).firstMatch
            XCTAssertTrue(predicateButton.waitForExistence(timeout: 3), "Sound button should exist")
            predicateButton.tap()
        }

        let navBar = app.navigationBars["Alarm Sound"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Sound picker should appear")
    }

    @MainActor
    private func swipeDownInForm(_ app: XCUIApplication) {
        // Drag from bottom to top to scroll content UP (reveal lower sections)
        let bottomCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let topCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        bottomCoordinate.press(forDuration: 0.1, thenDragTo: topCoordinate)
    }
}
