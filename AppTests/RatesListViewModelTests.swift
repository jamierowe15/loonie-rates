import XCTest
@testable import LoonieRates

@MainActor
final class RatesListViewModelTests: XCTestCase {
    func testStartsLoadingThenShowsFavouritesAndAll() async {
        let store = await TestSupport.store()
        let model = RatesListViewModel(store: store, favourites: TestSupport.favourites(), locale: TestLocales.english)
        XCTAssertEqual(model.state, .loading)
        await store.refresh()
        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.visibleSections, [.favourites, .all])
        XCTAssertEqual(model.codes(in: .favourites), ["USD", "EUR"])
        XCTAssertEqual(model.codes(in: .all).count, Currency.all.count)
        XCTAssertNil(model.bannerText)
    }

    func testSearchFiltersByNameOrCode() async {
        let store = await TestSupport.store()
        let model = RatesListViewModel(store: store, favourites: TestSupport.favourites(), locale: TestLocales.english)
        await store.refresh()
        model.searchText = "yen"
        XCTAssertEqual(model.codes(in: .all), ["JPY"])
        XCTAssertEqual(model.visibleSections, [.all])
        model.searchText = "chf"
        XCTAssertEqual(model.codes(in: .all), ["CHF"])
        model.searchText = "zzz"
        XCTAssertTrue(model.visibleSections.isEmpty)
    }

    func testToggleFavouriteNotifies() async {
        let store = await TestSupport.store()
        let model = RatesListViewModel(store: store, favourites: TestSupport.favourites(), locale: TestLocales.english)
        await store.refresh()
        var changes = 0
        model.onChange = { changes += 1 }
        model.toggleFavourite("GBP")
        XCTAssertEqual(model.codes(in: .favourites), ["USD", "EUR", "GBP"])
        XCTAssertEqual(changes, 1)
    }

    func testRowIsFormattedAndSpoken() async throws {
        let store = await TestSupport.store()
        let model = RatesListViewModel(store: store, favourites: TestSupport.favourites(), locale: TestLocales.english)
        await store.refresh()
        let row = try XCTUnwrap(model.row(for: "USD"))
        XCTAssertTrue(row.title.contains("🇺🇸"))
        XCTAssertTrue(row.accessibilityLabel.contains("USD"))
        XCTAssertFalse(row.accessibilityValue.contains("▲"), "VoiceOver should hear words, not arrows")
        XCTAssertEqual(row.rateText.count, 6) // "1.4xxx"
    }

    func testOfflineWithoutCacheShowsAnError() async {
        let store = await TestSupport.store(failing: true)
        let model = RatesListViewModel(store: store, favourites: TestSupport.favourites(), locale: TestLocales.english)
        await store.refresh()
        guard case .failed(let message) = model.state else { return XCTFail("Expected failed, got \(model.state)") }
        XCTAssertFalse(message.isEmpty)
    }

    func testOfflineWithCacheShowsBanner() async {
        let store = await TestSupport.store(failing: true, cachedFirst: true)
        let model = RatesListViewModel(store: store, favourites: TestSupport.favourites(), locale: TestLocales.english)
        await store.refresh()
        XCTAssertEqual(model.state, .loaded)
        XCTAssertNotNil(model.bannerText)
    }
}
