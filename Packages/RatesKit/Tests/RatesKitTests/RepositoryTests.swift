import XCTest
@testable import RatesKit

final class RepositoryTests: XCTestCase {
    func testLiveRatesAreReturnedAndSaved() async throws {
        let cache = RatesCache(directory: temporaryFolder())
        let repository = RatesRepository(provider: StubRatesProvider(), cache: cache, currencies: [Fixtures.usd])
        let snapshot = try await repository.load()
        XCTAssertEqual(snapshot.source, .live)
        let saved = await cache.load()
        XCTAssertEqual(saved?.series, snapshot.series)
    }

    func testOfflineFallsBackToTheCache() async throws {
        let cache = RatesCache(directory: temporaryFolder())
        let savedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let series = [StubRatesProvider().makeSeries(Fixtures.usd, count: 5)]
        try await cache.save(series, at: savedAt)

        let repository = RatesRepository(provider: StubRatesProvider(failing: true), cache: cache, currencies: [Fixtures.usd])
        let snapshot = try await repository.load()
        XCTAssertEqual(snapshot.source, .cached(savedAt: savedAt))
        XCTAssertEqual(snapshot.series, series)
    }

    func testOfflineWithNoCacheThrows() async {
        let repository = RatesRepository(provider: StubRatesProvider(failing: true),
                                         cache: RatesCache(directory: temporaryFolder()), currencies: [Fixtures.usd])
        do {
            _ = try await repository.load()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? RatesError, .offline)
        }
    }

    func testClearRemovesTheFile() async throws {
        let cache = RatesCache(directory: temporaryFolder())
        try await cache.save([StubRatesProvider().makeSeries(Fixtures.usd, count: 2)])
        await cache.clear()
        let loaded = await cache.load()
        XCTAssertNil(loaded)
    }

    func testHistoryComesFromTheProvider() async throws {
        let repository = RatesRepository(provider: StubRatesProvider(), cache: RatesCache(directory: temporaryFolder()))
        let series = try await repository.history(for: Fixtures.eur, count: 22)
        XCTAssertEqual(series.observations.count, 22)
    }
}
