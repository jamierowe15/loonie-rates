import XCTest

/// Captures every screen. scripts/ci/evidence.sh runs it in light, dark, the largest text
/// size and French (TEST_RUNNER_SHOTS_TAG names each set). Skipped in normal CI.
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureEveryScreen() {
        let app = launchApp()
        let usd = element(app, "rates.row.fav.USD")
        XCTAssertTrue(usd.waitForExistence(timeout: 10))
        capture("01-rates")

        usd.tap()
        XCTAssertTrue(app.staticTexts["detail.highLow"].waitForExistence(timeout: 10))
        sleep(1)
        capture("02-detail")

        openTab(app, 1)
        XCTAssertTrue(app.staticTexts["converter.result"].waitForExistence(timeout: 5))
        capture("03-converter")

        app.terminate()
        let offline = launchApp(offline: true)
        XCTAssertTrue(offline.staticTexts["rates.banner"].waitForExistence(timeout: 10))
        capture("04-offline")
    }

    private func capture(_ name: String) {
        let tag = ProcessInfo.processInfo.environment["SHOTS_TAG"] ?? "shot"
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(tag)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        if let folder = evidenceFolder() {
            try? screenshot.pngRepresentation.write(to: folder.appendingPathComponent("\(tag)-\(name).png"))
        }
    }
}
