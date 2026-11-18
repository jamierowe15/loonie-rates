import XCTest
@testable import RatesKit

final class ValetClientTests: XCTestCase {
    func testBuildsTheValetURL() {
        let client = ValetClient(transport: FakeTransport(.failure(SomeNetworkError())))
        let url = client.url(series: ["FXUSDCAD", "FXEURCAD"], recent: 5)
        XCTAssertEqual(url.absoluteString, "https://www.bankofcanada.ca/valet/observations/FXUSDCAD,FXEURCAD/json?recent=5")
    }

    func testLatestRatesAsksForFiveDaysOfEveryCurrency() async throws {
        let transport = FakeTransport(.success((Fixtures.valetData, 200)))
        let series = try await ValetClient(transport: transport).latestRates(for: [Fixtures.usd, Fixtures.eur])
        XCTAssertEqual(series.count, 2)
        XCTAssertEqual(transport.requested.first?.query, "recent=5")
    }

    func testHistoryReturnsOneSeries() async throws {
        let transport = FakeTransport(.success((Fixtures.valetData, 200)))
        let series = try await ValetClient(transport: transport).history(for: Fixtures.usd, count: 250)
        XCTAssertEqual(series.currency, Fixtures.usd)
        XCTAssertEqual(transport.requested.first?.query, "recent=250")
    }

    func testNetworkFailureBecomesOffline() async {
        await assertThrows(.offline, FakeTransport(.failure(SomeNetworkError())))
    }

    func testServerErrorKeepsTheStatus() async {
        await assertThrows(.server(status: 503), FakeTransport(.success((Data(), 503))))
    }

    func testNoMatchingSeriesIsNoData() async {
        let transport = FakeTransport(.success((Fixtures.valetData, 200)))
        do {
            _ = try await ValetClient(transport: transport).history(for: Fixtures.jpy, count: 5)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? RatesError, .noData)
        }
    }

    private func assertThrows(_ expected: RatesError, _ transport: FakeTransport,
                              file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await ValetClient(transport: transport).latestRates(for: [Fixtures.usd])
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? RatesError, expected, file: file, line: line)
        }
    }
}
