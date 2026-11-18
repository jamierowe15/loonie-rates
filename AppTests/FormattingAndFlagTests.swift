import XCTest
@testable import LoonieRates

final class FormattingAndFlagTests: XCTestCase {
    func testObjectiveCFlagHelper() {
        XCTAssertEqual(Flags.emoji(for: "USD"), "🇺🇸")
        XCTAssertEqual(Flags.emoji(for: "EUR"), "🇪🇺")
        XCTAssertEqual(Flags.emoji(for: "jpy"), "🇯🇵")
        XCTAssertEqual(Flags.emoji(for: "1X"), "")
        XCTAssertEqual(Flags.emoji(for: "U"), "")
    }

    func testRatesUseFourOrSixDecimals() {
        XCTAssertEqual(Formatters.rate(Decimal(string: "1.3978") ?? 0, locale: TestLocales.english), "1.3978")
        XCTAssertEqual(Formatters.rate(Decimal(string: "1.3978") ?? 0, locale: TestLocales.french), "1,3978")
        XCTAssertEqual(Formatters.rate(Decimal(string: "0.009127") ?? 0, locale: TestLocales.english), "0.009127")
    }

    func testMoneyFollowsTheLocale() {
        let value = Decimal(string: "139.78") ?? 0
        XCTAssertEqual(Formatters.money(value, currency: .cad, locale: TestLocales.english), "$139.78")
        XCTAssertTrue(Formatters.money(value, currency: .cad, locale: TestLocales.french).hasPrefix("139,78"))
    }

    func testTrendHasAnArrow() {
        let up = StubRatesProvider().makeSeries(Currency.all[0], count: 5)
        XCTAssertTrue(["▲", "▼", "–"].contains { Formatters.trend(up, locale: TestLocales.english).hasPrefix($0) })
    }
}
