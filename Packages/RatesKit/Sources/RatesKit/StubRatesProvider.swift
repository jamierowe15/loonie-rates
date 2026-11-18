import Foundation

/// Fake but believable rates, the same every time. Used by UI tests and screenshots so they
/// never depend on the internet or on today's rates. `failing: true` simulates being offline.
public struct StubRatesProvider: RatesProviding {
    public static let baseRates: [String: Double] = [
        "USD": 1.3978, "EUR": 1.6204, "GBP": 1.8391, "JPY": 0.009127, "CNY": 0.1937, "AUD": 0.9105,
        "CHF": 1.7462, "MXN": 0.0761, "INR": 0.01658, "HKD": 0.1797, "NZD": 0.8012, "SEK": 0.1484,
    ]

    private let failing: Bool

    public init(failing: Bool = false) {
        self.failing = failing
    }

    public func latestRates(for currencies: [Currency]) async throws -> [RateSeries] {
        if failing { throw RatesError.offline }
        return currencies.map { makeSeries($0, count: 5) }
    }

    public func history(for currency: Currency, count: Int) async throws -> RateSeries {
        if failing { throw RatesError.offline }
        return makeSeries(currency, count: count)
    }

    /// `count` weekdays ending on Friday 13 November 2026, gently waving around the base rate.
    public func makeSeries(_ currency: Currency, count: Int) -> RateSeries {
        let base = Self.baseRates[currency.code] ?? 1
        let days = Self.weekdays(endingOn: "2026-11-13", count: count)
        let observations = days.enumerated().compactMap { index, day -> RateObservation? in
            let wave = sin(Double(index) / 7) * 0.015 + Double(index % 3) * 0.001
            let value = Converter.round(Decimal(base * (1 + wave)), places: 6)
            return RateObservation(day: day, value: value)
        }
        return RateSeries(currency: currency, observations: observations)
    }

    static func weekdays(endingOn last: String, count: Int) -> [String] {
        guard count > 0, var date = ValetDate.parse(last) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        var result: [String] = []
        while result.count < count {
            let weekday = calendar.component(.weekday, from: date) // 1 = Sunday, 7 = Saturday
            if weekday != 1 && weekday != 7 {
                result.append(ValetDate.string(from: date))
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return result.reversed()
    }
}
