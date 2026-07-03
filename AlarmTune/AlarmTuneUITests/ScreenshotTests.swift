//
//  ScreenshotTests.swift
//  AlarmTuneUITests
//
//  Screenshot capture for visual UI verification
//

import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Empty state (alarm list)
        let emptyAddButton = app.buttons["addAlarmEmptyButton"]
        let toolbarAddButton = app.buttons["addAlarmToolbarButton"]
        let emptyExists = emptyAddButton.waitForExistence(timeout: 3)
        let toolbarExists = toolbarAddButton.waitForExistence(timeout: 1)

        if emptyExists {
            captureScreenshot(app, named: "01_EmptyState")
            emptyAddButton.tap()
        } else if toolbarExists {
            toolbarAddButton.tap()
        }

        // 2. Add Alarm form
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 5) {
            captureScreenshot(app, named: "02_AddAlarmForm")

            // 3. Scroll to Sound section and tap
            let soundButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Sound'")
            ).firstMatch
            if !soundButton.waitForExistence(timeout: 2) {
                let formCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
                let bottomCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                formCoordinate.press(forDuration: 0.1, thenDragTo: bottomCoordinate)
            }
            if soundButton.waitForExistence(timeout: 3) {
                soundButton.tap()
            }

            // 4. Sound Picker (top)
            let navBar = app.navigationBars["Alarm Sound"]
            if navBar.waitForExistence(timeout: 5) {
                captureScreenshot(app, named: "03_SoundPicker_Top")

                // 5. Scroll down to see Apple Music / Imported sections
                let startCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                let endCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
                startCoord.press(forDuration: 0.1, thenDragTo: endCoord)
                captureScreenshot(app, named: "04_SoundPicker_Bottom")
            }
        }
    }

    private func captureScreenshot(_ app: XCUIApplication, named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
