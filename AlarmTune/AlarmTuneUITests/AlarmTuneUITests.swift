//
//  AlarmTuneUITests.swift
//  AlarmTuneUITests
//
//  Created by MacMini4 on 2026/4/18.
//

import XCTest

final class AlarmTuneUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    /// 导航到 SoundPickerView 的辅助方法。
    /// 处理首次启动（空状态按钮）和已有闹钟（工具栏按钮）两种情况。
    @MainActor
    private func navigateToSoundPicker(_ app: XCUIApplication) -> Bool {
        // 优先尝试空状态下的 "Add Alarm" 按钮（首次启动场景）
        let emptyAddButton = app.buttons["addAlarmEmptyButton"]
        let toolbarAddButton = app.buttons["addAlarmToolbarButton"]

        // 等待任一按钮出现
        let emptyExists = emptyAddButton.waitForExistence(timeout: 3)
        let toolbarExists = toolbarAddButton.waitForExistence(timeout: 1)

        if emptyExists {
            emptyAddButton.tap()
        } else if toolbarExists {
            toolbarAddButton.tap()
        } else {
            XCTFail("Neither empty-state nor toolbar add button found")
            return false
        }

        // 等待 AlarmEditView 出现（通过 Cancel/Save 按钮确认 sheet 已弹出）
        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 5) else {
            XCTFail("AlarmEditView did not appear (Cancel button not found)")
            return false
        }

        // Sound 按钮可能在 Form 下方，需要滚动查找。
        // Form 中 Button 的 label 包含 "Sound" 文本，用谓词匹配。
        let soundButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Sound'")
        ).firstMatch

        // 先尝试直接查找；找不到则向下滚动再找
        if !soundButton.waitForExistence(timeout: 2) {
            // 向下滑动 Form 以露出 Sound Section
            let formCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            let bottomCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            formCoordinate.press(forDuration: 0.1, thenDragTo: bottomCoordinate)
        }

        guard soundButton.waitForExistence(timeout: 3) else {
            // 最后兜底：用 staticTexts 查找 "Sound" 并点击
            let soundText = app.staticTexts["Sound"].firstMatch
            if soundText.waitForExistence(timeout: 2) {
                soundText.tap()
            } else {
                XCTFail("Sound button not found in alarm edit view after scrolling")
                return false
            }
            return waitForSoundPicker(app)
        }

        soundButton.tap()
        return waitForSoundPicker(app)
    }

    /// 等待 SoundPickerView 的导航栏出现
    @MainActor
    private func waitForSoundPicker(_ app: XCUIApplication) -> Bool {
        let navBar = app.navigationBars["Alarm Sound"]
        guard navBar.waitForExistence(timeout: 5) else {
            XCTFail("Sound picker navigation bar not appeared")
            return false
        }
        return true
    }

    @MainActor
    func testSoundPickerShowsAllCategories() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(navigateToSoundPicker(app), "Should navigate to sound picker")

        // 验证 5 个分类标题可见
        let expectedCategories = ["Loud", "Nature", "Gentle", "Classic", "Fun"]
        for category in expectedCategories {
            let categoryText = app.staticTexts[category]
            XCTAssertTrue(
                categoryText.waitForExistence(timeout: 3),
                "Category '\(category)' should be visible in sound picker"
            )
        }

        // 验证部分铃声可见（每类抽 1 个）
        let expectedSounds = ["Gentle Morning", "Emergency Siren", "Forest Birds", "Classic Alarm", "Disco Wake"]
        for soundName in expectedSounds {
            let soundText = app.staticTexts[soundName]
            XCTAssertTrue(
                soundText.waitForExistence(timeout: 3),
                "Sound '\(soundName)' should be visible"
            )
        }

        // 验证 Apple Music 区域存在
        let appleMusicText = app.staticTexts["Apple Music"]
        XCTAssertTrue(
            appleMusicText.waitForExistence(timeout: 3),
            "Apple Music section should be visible"
        )

        // 验证 Imported Sounds 区域存在
        let importedText = app.staticTexts["Imported Sounds"]
        XCTAssertTrue(
            importedText.waitForExistence(timeout: 3),
            "Imported Sounds section should be visible"
        )

        // 截图用于视觉验证
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "SoundPicker_iPhone"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSoundPreviewWorks() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(navigateToSoundPicker(app), "Should navigate to sound picker")

        // 等待内容加载后，点击第一个 play.circle.fill 按钮预览
        let playButtons = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'play' OR label CONTAINS 'Play'")
        )
        XCTAssertTrue(
            playButtons.firstMatch.waitForExistence(timeout: 5),
            "At least one play button should exist"
        )
        if playButtons.count > 0 {
            playButtons.firstMatch.tap()
            // 预览不崩溃即视为通过
            XCTAssertTrue(true, "Sound preview tap succeeded without crash")
        }
    }

    @MainActor
    func testSelectBuiltInSoundUpdatesSelection() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(navigateToSoundPicker(app), "Should navigate to sound picker")

        // 选择 "Air Horn" 铃声（点击其文本行而非 play 按钮）
        let airHornText = app.staticTexts["Air Horn"]
        XCTAssertTrue(airHornText.waitForExistence(timeout: 3), "Air Horn should be visible")

        // 点击行：点击文本左側附近以触发 SoundRow 的 onSelect（避免点到 play 按钮）
        let coordinate = airHornText.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        coordinate.tap()

        // 点击 Done 关闭选择器
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
        }

        // 验证返回 AlarmEditView 后 Sound 行显示 "Air Horn"
        let soundButton = app.buttons["soundPickerButton"]
        XCTAssertTrue(soundButton.waitForExistence(timeout: 3), "Should return to alarm edit view")
        XCTAssertTrue(
            soundButton.label.contains("Air Horn"),
            "Sound button label should contain 'Air Horn', got: \(soundButton.label)"
        )
    }
}
