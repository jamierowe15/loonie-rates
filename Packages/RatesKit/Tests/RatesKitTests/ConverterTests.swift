import XCTest
@testable import RatesKit

final class ConverterTests: XCTestCase {
    private let rate = Fixtures.decimal("1.3978")

    func testForeignToCADRoundsToTheCent() {
        // 100 USD x 1.3978 = 139.78 CAD
        XCTAssertEqual(Converter.convert(100, rate: rate, direction: .toCAD, currency: Fixtures.usd), Fixtures.decimal("139.78"))
    }

    func testCADToForeign() {
        // 100 CAD / 1.3978 = 71.5410... -> 71.54 USD
        XCTAssertEqual(Converter.convert(100, rate: rate, direction: .fromCAD, currency: Fixtures.usd), Fixtures.decimal("71.54"))
    }

    func testYenHasNoDecimals() {
        // 100 CAD / 0.009127 = 10956.5... -> 10957 JPY
        let result = Converter.convert(100, rate: Fixtures.decimal("0.009127"), direction: .fromCAD, currency: Fixtures.jpy)
        XCTAssertEqual(result, Fixtures.decimal("10957"))
    }

    func testRoundsHalfUp() {
        XCTAssertEqual(Converter.round(Fixtures.decimal("0.005"), places: 2), Fixtures.decimal("0.01"))
        XCTAssertEqual(Converter.round(Fixtures.decimal("2.344"), places: 2), Fixtures.decimal("2.34"))
    }

    func testDecimalAvoidsFloatingPointErrors() {
        XCTAssertEqual(Fixtures.decimal("0.1") + Fixtures.decimal("0.2"), Fixtures.decimal("0.3"))
    }

    func testRejectsBadInput() {
        XCTAssertNil(Converter.convert(100, rate: 0, direction: .toCAD, currency: Fixtures.usd))
        XCTAssertNil(Converter.convert(-1, rate: rate, direction: .toCAD, currency: Fixtures.usd))
    }

    func testParsesEnglishAndFrenchAmounts() {
        XCTAssertEqual(AmountParser.parse("1,234.56"), Fixtures.decimal("1234.56"))
        XCTAssertEqual(AmountParser.parse("$42"), Fixtures.decimal("42"))
        XCTAssertEqual(AmountParser.parse("1 234,56", decimalSeparator: ","), Fixtures.decimal("1234.56"))
        XCTAssertEqual(AmountParser.parse("1\u{202F}234,5", decimalSeparator: ","), Fixtures.decimal("1234.5"))
    }

    func testRejectsNonsenseAmounts() {
        XCTAssertNil(AmountParser.parse(""))
        XCTAssertNil(AmountParser.parse("."))
        XCTAssertNil(AmountParser.parse("12a"))
        XCTAssertNil(AmountParser.parse("1.2.3"))
        XCTAssertNil(AmountParser.parse("-5"))
    }
}
