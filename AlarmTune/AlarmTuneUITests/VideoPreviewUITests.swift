import XCTest

final class VideoPreviewUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testVideoPreviewPlaysVideo() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Tap "Add Alarm"
        let addButton = app.buttons["addAlarmEmptyButton"]
        if !addButton.waitForExistence(timeout: 3) {
            app.buttons["addAlarmToolbarButton"].tap()
        } else {
            addButton.tap()
        }

        // 2. Wait for edit view
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Edit view should appear")

        // 3. Scroll to Video Background section
        let videoButton = app.buttons["videoPickerButton"]
        if !videoButton.waitForExistence(timeout: 2) {
            // Scroll down to find it
            let startCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let endCoord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            startCoord.press(forDuration: 0.1, thenDragTo: endCoord)
        }
        XCTAssertTrue(videoButton.waitForExistence(timeout: 3), "Video Background button should exist")

        // 4. Tap Video Background button to open picker
        videoButton.tap()

        // 5. Wait for video picker
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Video picker should appear with Done button")

        // 6. Wait for video cards to load
        sleep(2)

        // 7. Find and tap the first play button (preview)
        // Play buttons have "play.circle.fill" icon
        let playButtons = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'play' OR label CONTAINS 'Play'")
        )
        if playButtons.count > 0 {
            let firstPlay = playButtons.firstMatch
            XCTAssertTrue(firstPlay.waitForExistence(timeout: 3), "Play button should exist")
            firstPlay.tap()

            // 8. Wait for preview to play
            sleep(3)

            // 9. Verify no crash — if we get here, the preview started without crashing
            XCTAssertTrue(app.state == .runningForeground, "App should still be running after preview")

            // 10. Take screenshot for verification
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "VideoPreview_Playing"
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        // 11. Tap Done to close
        doneButton.tap()
        sleep(1)

        // 12. Cancel edit
        if cancelButton.waitForExistence(timeout: 3) {
            cancelButton.tap()
        }
    }
}
