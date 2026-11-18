import XCTest
@testable import RatesKit

final class StoreAndStubTests: XCTestCase {
    func testFavouritesStartWithUSDAndEURThenToggle() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "test-\(UUID().uuidString)"))
        let store = FavouritesStore(defaults: defaults)
        XCTAssertEqual(store.codes, ["USD", "EUR"])
        store.toggle("JPY")
        XCTAssertTrue(store.isFavourite("JPY"))
        store.toggle("USD")
        XCTAssertFalse(store.isFavourite("USD"))
        XCTAssertEqual(store.codes, ["EUR", "JPY"])
    }

    func testStubSkipsWeekendsAndIsRepeatable() {
        let days = StubRatesProvider.weekdays(endingOn: "2026-11-13", count: 6)
        XCTAssertEqual(days, ["2026-11-06", "2026-11-09", "2026-11-10", "2026-11-11", "2026-11-12", "2026-11-13"])
        let first = StubRatesProvider().makeSeries(Fixtures.usd, count: 30)
        let second = StubRatesProvider().makeSeries(Fixtures.usd, count: 30)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.observations.count, 30)
    }

    func testFailingStubIsOffline() async {
        do {
            _ = try await StubRatesProvider(failing: true).latestRates(for: [Fixtures.usd])
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? RatesError, .offline)
        }
    }
}
