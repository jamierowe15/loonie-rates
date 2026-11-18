import XCTest

/// The journeys a real person takes. Elements are found by accessibility identifier, never by
/// on-screen text, so the same tests pass in English and French.
final class MainFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testOpenRateChartAndConvert() {
        let app = launchApp()
        let usd = element(app, "rates.row.fav.USD")
        XCTAssertTrue(usd.waitForExistence(timeout: 10))
        demoPause()
        usd.tap()

        XCTAssertTrue(app.staticTexts["detail.rate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["detail.highLow"].waitForExistence(timeout: 10), "The chart's range summary should load")
        demoPause()
        app.segmentedControls["detail.range"].buttons.element(boundBy: 2).tap()
        demoPause(2)

        app.buttons["detail.convert"].tap()
        let amount = app.textFields["converter.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.replaceText("250")
        demoPause()
        let result = app.staticTexts["converter.result"]
        XCTAssertTrue(result.label.contains("US$") || result.label.contains("$"), result.label)

        app.segmentedControls["converter.direction"].buttons.element(boundBy: 1).tap()
        demoPause(2)
        XCTAssertTrue(result.label.contains("$"), result.label)
    }

    func testSearchFindsTheYen() {
        let app = launchApp()
        XCTAssertTrue(element(app, "rates.row.all.USD").waitForExistence(timeout: 10))
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("yen")
        XCTAssertTrue(element(app, "rates.row.all.JPY").waitForExistence(timeout: 5))
        XCTAssertFalse(element(app, "rates.row.all.USD").exists)
    }

    func testSwipeToFavourite() {
        let app = launchApp()
        let pound = element(app, "rates.row.all.GBP")
        XCTAssertTrue(pound.waitForExistence(timeout: 10))
        XCTAssertFalse(element(app, "rates.row.fav.GBP").exists)
        pound.swipeLeft()
        app.buttons["Favourite"].tap()
        XCTAssertTrue(element(app, "rates.row.fav.GBP").waitForExistence(timeout: 5))
    }

    func testOfflineShowsSavedRatesWithABanner() {
        let app = launchApp(offline: true)
        let banner = app.staticTexts["rates.banner"]
        XCTAssertTrue(banner.waitForExistence(timeout: 10))
        XCTAssertTrue(banner.label.contains("Offline"), banner.label)
        XCTAssertTrue(element(app, "rates.row.fav.USD").exists, "Saved rates should still be listed")
    }

    func testEverythingIsInFrench() {
        let app = launchApp(french: true)
        XCTAssertTrue(element(app, "rates.row.fav.USD").waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Taux de change"].exists)
        openTab(app, 1)
        let result = app.staticTexts["converter.result"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        // 100 $ CA en dollars américains: une virgule décimale et « $ US ».
        XCTAssertTrue(result.label.contains(","), result.label)
        XCTAssertTrue(app.navigationBars["Convertisseur"].exists)
    }
}
