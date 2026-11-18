import Foundation

/// Anything that can supply rates. The app uses `ValetClient`; UI tests use `StubRatesProvider`.
public protocol RatesProviding: Sendable {
    /// The last few days of every currency, so each series has a latest and a previous rate.
    func latestRates(for currencies: [Currency]) async throws -> [RateSeries]
    /// The last `count` published rates for one currency, for the chart.
    func history(for currency: Currency, count: Int) async throws -> RateSeries
}

/// Talks to the Bank of Canada's free, public Valet API. No key, no sign-in.
/// Docs: https://www.bankofcanada.ca/valet/docs
public struct ValetClient: RatesProviding {
    public static let baseURL = URL(string: "https://www.bankofcanada.ca/valet")!

    private let transport: HTTPTransport

    public init(transport: HTTPTransport = URLSessionTransport()) {
        self.transport = transport
    }

    /// https://www.bankofcanada.ca/valet/observations/FXUSDCAD,FXEURCAD/json?recent=5
    public func url(series: [String], recent: Int) -> URL {
        let path = "observations/\(series.joined(separator: ","))/json"
        let address = Self.baseURL.appendingPathComponent(path)
        guard var components = URLComponents(url: address, resolvingAgainstBaseURL: false) else { return address }
        components.queryItems = [URLQueryItem(name: "recent", value: String(recent))]
        return components.url ?? address
    }

    public func latestRates(for currencies: [Currency]) async throws -> [RateSeries] {
        // 5 rows, not 2: if a country had a holiday, its series still gets two values.
        try await fetch(currencies: currencies, recent: 5)
    }

    public func history(for currency: Currency, count: Int) async throws -> RateSeries {
        guard let series = try await fetch(currencies: [currency], recent: count).first else {
            throw RatesError.noData
        }
        return series
    }

    private func fetch(currencies: [Currency], recent: Int) async throws -> [RateSeries] {
        let response: (Data, Int)
        do {
            response = try await transport.get(url(series: currencies.map(\.seriesName), recent: recent))
        } catch {
            throw RatesError.offline
        }
        let (data, status) = response
        guard (200..<300).contains(status) else { throw RatesError.server(status: status) }
        let series = try ValetParser.series(from: data, currencies: currencies)
        guard !series.isEmpty else { throw RatesError.noData }
        return series
    }
}
