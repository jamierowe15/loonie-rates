import XCTest
@testable import RatesKit

final class RateSeriesTests: XCTestCase {
    func testChangeAndPercentChange() throws {
        let series = Fixtures.series(Fixtures.usd, [("2026-11-12", "1.40"), ("2026-11-13", "1.47")])
        XCTAssertEqual(series.change, Fixtures.decimal("0.07"))
        XCTAssertEqual(series.percentChange.map { Converter.round($0, places: 4) }, Fixtures.decimal("5"))
        XCTAssertEqual(series.trend, .up)
    }

    func testDownAndFlat() {
        let down = Fixtures.series(Fixtures.usd, [("2026-11-12", "1.40"), ("2026-11-13", "1.39")])
        XCTAssertEqual(down.trend, .down)
        let flat = Fixtures.series(Fixtures.usd, [("2026-11-12", "1.40"), ("2026-11-13", "1.40")])
        XCTAssertEqual(flat.trend, .flat)
    }

    func testSingleObservationHasNoChange() {
        let series = Fixtures.series(Fixtures.usd, [("2026-11-13", "1.40")])
        XCTAssertNil(series.change)
        XCTAssertNil(series.percentChange)
        XCTAssertEqual(series.trend, .flat)
    }

    func testInitSortsAndFindsHighLow() {
        let series = Fixtures.series(Fixtures.usd, [("2026-11-13", "1.39"), ("2026-11-11", "1.41"), ("2026-11-12", "1.38")])
        XCTAssertEqual(series.observations.first?.day, "2026-11-11")
        XCTAssertEqual(series.highest, Fixtures.decimal("1.41"))
        XCTAssertEqual(series.lowest, Fixtures.decimal("1.38"))
    }

    func testFrenchAndEnglishNames() {
        XCTAssertEqual(Fixtures.usd.name(languageCode: "fr"), "Dollar américain")
        XCTAssertEqual(Fixtures.usd.name(languageCode: "en"), "US dollar")
        XCTAssertEqual(Fixtures.usd.seriesName, "FXUSDCAD")
        XCTAssertNil(Currency.withCode("XYZ"))
    }
}
