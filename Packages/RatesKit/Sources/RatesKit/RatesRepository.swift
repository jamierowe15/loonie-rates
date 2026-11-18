import Foundation

/// Where the rates on screen came from.
public enum RatesSource: Equatable, Sendable {
    case live
    case cached(savedAt: Date)
}

public struct RatesSnapshot: Equatable, Sendable {
    public let series: [RateSeries]
    public let source: RatesSource
}

/// The single place screens ask for rates. Tries the network, saves what it gets, and falls
/// back to the saved copy when the network fails. Screens never talk to the API directly.
public struct RatesRepository: Sendable {
    private let provider: RatesProviding
    private let cache: RatesCache
    public let currencies: [Currency]

    public init(provider: RatesProviding, cache: RatesCache, currencies: [Currency] = Currency.all) {
        self.provider = provider
        self.cache = cache
        self.currencies = currencies
    }

    public func load() async throws -> RatesSnapshot {
        do {
            let live = try await provider.latestRates(for: currencies)
            try? await cache.save(live)
            return RatesSnapshot(series: live, source: .live)
        } catch {
            if let saved = await cache.load(), !saved.series.isEmpty {
                return RatesSnapshot(series: saved.series, source: .cached(savedAt: saved.savedAt))
            }
            throw error
        }
    }

    public func history(for currency: Currency, count: Int) async throws -> RateSeries {
        try await provider.history(for: currency, count: count)
    }
}
