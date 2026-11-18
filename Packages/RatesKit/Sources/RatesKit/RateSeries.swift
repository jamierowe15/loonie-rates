import Foundation

/// One published rate: on `day`, 1 unit of the foreign currency cost `value` Canadian dollars.
public struct RateObservation: Hashable, Codable, Sendable {
    /// The day exactly as the Bank publishes it, "2026-11-13".
    public let day: String
    /// The same day as a Date (midnight UTC), for charts.
    public let date: Date
    /// Decimal, never Double: binary floating point can't store 0.1 exactly.
    public let value: Decimal

    /// Returns nil if `day` isn't a valid yyyy-MM-dd date.
    public init?(day: String, value: Decimal) {
        guard let date = ValetDate.parse(day) else { return nil }
        self.day = day
        self.date = date
        self.value = value
    }

    // Saved as text ({"day": "2026-11-13", "value": "1.3978"}) so the cache round-trips exactly.
    // Some JSONDecoder versions read numbers through Double, which would turn 1.3978 into 1.39779999...
    private enum CodingKeys: String, CodingKey { case day, value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let day = try container.decode(String.self, forKey: .day)
        let text = try container.decode(String.self, forKey: .value)
        guard let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")),
              let date = ValetDate.parse(day) else {
            throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Bad saved rate")
        }
        self.day = day
        self.date = date
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode("\(value)", forKey: .value)
    }
}

public enum Trend: String, Sendable {
    case up, down, flat
}

/// A currency and its observations, oldest first.
public struct RateSeries: Hashable, Codable, Sendable, Identifiable {
    public let currency: Currency
    public let observations: [RateObservation]

    public var id: String { currency.code }

    public init(currency: Currency, observations: [RateObservation]) {
        self.currency = currency
        self.observations = observations.sorted { $0.day < $1.day }
    }

    public var latest: RateObservation? { observations.last }

    public var previous: RateObservation? {
        observations.count > 1 ? observations[observations.count - 2] : nil
    }

    /// Latest minus previous, in Canadian dollars.
    public var change: Decimal? {
        guard let latest, let previous else { return nil }
        return latest.value - previous.value
    }

    /// The change as a percentage of the previous rate.
    public var percentChange: Decimal? {
        guard let change, let previous, previous.value != 0 else { return nil }
        return change / previous.value * 100
    }

    public var trend: Trend {
        guard let change else { return .flat }
        if change > 0 { return .up }
        if change < 0 { return .down }
        return .flat
    }

    public var lowest: Decimal? { observations.map(\.value).min() }
    public var highest: Decimal? { observations.map(\.value).max() }
}

/// Parses "yyyy-MM-dd" without DateFormatter (which is slow to create and depends on the
/// phone's settings). Calendar maths in UTC gives the same answer on every device.
public enum ValetDate {
    public static func parse(_ text: String) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        guard let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
            return nil
        }
        // Calendar quietly turns 30 February into 2 March; reject dates that moved.
        let check = calendar.dateComponents([.year, .month, .day], from: date)
        guard check.year == parts[0], check.month == parts[1], check.day == parts[2] else { return nil }
        return date
    }

    /// The reverse: a Date back to "yyyy-MM-dd" (UTC).
    public static func string(from date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(pad(parts.month ?? 0))-\(pad(parts.day ?? 0))"
    }

    private static func pad(_ number: Int) -> String {
        number < 10 ? "0\(number)" : "\(number)"
    }
}
