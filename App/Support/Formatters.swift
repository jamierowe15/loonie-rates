import Foundation
import RatesKit

/// Turns numbers and dates into text for a locale. "1.3978" in English is "1,3978" in French,
/// and "$139.78" is "139,78 $". Never build these strings by hand.
enum Formatters {
    /// A Bank of Canada rate: 4 decimals, or 6 for tiny rates like the yen (0.009127).
    static func rate(_ value: Decimal, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        let threshold = Decimal(string: "0.1") ?? 0
        let digits = value < threshold ? 6 : 4
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    /// An amount of money in a currency: "US$71.54", "10 957 ¥", "139,78 $".
    static func money(_ value: Decimal, currency: Currency, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.code
        formatter.minimumFractionDigits = currency.decimals
        formatter.maximumFractionDigits = currency.decimals
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value) \(currency.code)"
    }

    /// 0.17 (meaning 0.17%) -> "0.17%" or "0,17 %". Always positive; the arrow shows direction.
    static func percent(_ value: Decimal, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let magnitude = value < 0 ? -value : value
        return formatter.string(from: NSDecimalNumber(decimal: magnitude / 100)) ?? "\(magnitude)%"
    }

    /// "Nov 13, 2026" / "13 nov. 2026". Rates are per day, so the time zone is UTC.
    static func day(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// "Nov 14, 2026 at 9:41 AM" in the phone's time zone, for "saved at".
    static func dateTime(_ date: Date, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// "▲ 0.17%": an arrow as well as a colour, so the trend doesn't depend on seeing colour.
    static func trend(_ series: RateSeries, locale: Locale = .current) -> String {
        guard let change = series.percentChange else { return "–" }
        let arrow: String
        switch series.trend {
        case .up: arrow = "▲"
        case .down: arrow = "▼"
        case .flat: arrow = "–"
        }
        return "\(arrow) \(percent(change, locale: locale))"
    }

    /// What VoiceOver says instead of the arrow: "Up 0.17% since the previous day".
    static func spokenTrend(_ series: RateSeries, locale: Locale = .current) -> String {
        guard let change = series.percentChange else { return L10n.text("a11y.trend.none") }
        switch series.trend {
        case .up: return L10n.format("a11y.trend.up", percent(change, locale: locale))
        case .down: return L10n.format("a11y.trend.down", percent(change, locale: locale))
        case .flat: return L10n.text("a11y.trend.flat")
        }
    }
}

extension Currency {
    /// The Canadian dollar itself, for showing converted amounts. Not in `Currency.all`
    /// because the Bank publishes rates against it, not for it.
    static let cad = Currency(code: "CAD", englishName: "Canadian dollar", frenchName: "Dollar canadien")

    /// Name in the app's current language.
    var localizedName: String { name(languageCode: L10n.languageCode) }

    var flag: String { Flags.emoji(for: code) }
}

extension RatesError {
    /// A sentence a person can act on, never a raw error code.
    var message: String {
        switch self {
        case .offline: return L10n.text("error.offline")
        case .server(let status): return L10n.format("error.server", String(status))
        case .decoding: return L10n.text("error.decoding")
        case .noData: return L10n.text("error.noData")
        }
    }
}
