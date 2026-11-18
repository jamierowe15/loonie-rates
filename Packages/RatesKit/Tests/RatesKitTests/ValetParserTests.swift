import XCTest
@testable import RatesKit

final class ValetParserTests: XCTestCase {
    func testDecodesEverySeriesAndSortsOldestFirst() throws {
        let series = try ValetParser.series(from: Fixtures.valetData, currencies: [Fixtures.usd, Fixtures.eur])
        XCTAssertEqual(series.map(\.currency.code), ["USD", "EUR"])
        let usd = try XCTUnwrap(series.first)
        XCTAssertEqual(usd.observations.map(\.day), ["2026-11-11", "2026-11-12", "2026-11-13"])
        XCTAssertEqual(usd.latest?.value, Fixtures.decimal("1.3978"))
    }

    func testMissingDayIsSkippedNotZero() throws {
        let series = try ValetParser.series(from: Fixtures.valetData, currencies: [Fixtures.eur])
        let eur = try XCTUnwrap(series.first)
        XCTAssertEqual(eur.observations.count, 2)
        XCTAssertEqual(eur.latest?.day, "2026-11-12")
    }

    func testCurrencyNotInResponseIsLeftOut() throws {
        let series = try ValetParser.series(from: Fixtures.valetData, currencies: [Fixtures.jpy])
        XCTAssertTrue(series.isEmpty)
    }

    func testBrokenJSONThrowsDecodingError() {
        XCTAssertThrowsError(try ValetParser.series(from: Data("not json".utf8), currencies: [Fixtures.usd])) { error in
            guard case RatesError.decoding = error else { return XCTFail("Expected .decoding, got \(error)") }
        }
    }

    func testRowWithoutDateThrows() {
        let json = #"{ "observations": [ { "FXUSDCAD": { "v": "1.39" } } ] }"#
        XCTAssertThrowsError(try ValetParser.series(from: Data(json.utf8), currencies: [Fixtures.usd]))
    }

    func testValetDateRoundTrips() throws {
        let date = try XCTUnwrap(ValetDate.parse("2026-01-05"))
        XCTAssertEqual(ValetDate.string(from: date), "2026-01-05")
    }

    func testValetDateRejectsNonsense() {
        XCTAssertNotNil(ValetDate.parse("2026-02-28"))
        XCTAssertNil(ValetDate.parse("2026-02-30"))
        XCTAssertNil(ValetDate.parse("2026-13-01"))
        XCTAssertNil(ValetDate.parse("yesterday"))
    }
}
