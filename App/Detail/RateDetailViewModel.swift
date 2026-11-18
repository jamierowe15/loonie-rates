import Foundation
import RatesKit

@MainActor
final class RateDetailViewModel {
    /// The chart's time ranges and how many daily rates each one needs (markets close on weekends).
    enum Range: Int, CaseIterable {
        case month, quarter, year

        var count: Int {
            switch self {
            case .month: return 22
            case .quarter: return 65
            case .year: return 250
            }
        }

        var title: String {
            switch self {
            case .month: return L10n.text("detail.range.month")
            case .quarter: return L10n.text("detail.range.quarter")
            case .year: return L10n.text("detail.range.year")
            }
        }
    }

    enum ChartState: Equatable {
        case loading, loaded([ChartPoint]), failed(String)
    }

    let currency: Currency
    private(set) var range: Range = .month
    private(set) var chart: ChartState = .loading {
        didSet { onChange?() }
    }
    var onChange: (() -> Void)?

    private let store: RatesStore
    private let favourites: FavouritesStore
    private let locale: Locale
    private var history: RateSeries?

    init(currency: Currency, store: RatesStore, favourites: FavouritesStore, locale: Locale = .current) {
        self.currency = currency
        self.store = store
        self.favourites = favourites
        self.locale = locale
    }

    var title: String { "\(currency.flag) \(currency.code)" }
    var subtitle: String { currency.localizedName }

    private var latestSeries: RateSeries? { store.series(for: currency.code) }

    /// "1 USD = 1.3978 CAD"
    var rateText: String {
        guard let latest = latestSeries?.latest else { return "–" }
        return L10n.format("detail.rate", currency.code, Formatters.rate(latest.value, locale: locale))
    }

    var trendText: String { latestSeries.map { Formatters.trend($0, locale: locale) } ?? "" }
    var trend: Trend { latestSeries?.trend ?? .flat }
    var spokenTrend: String { latestSeries.map { Formatters.spokenTrend($0, locale: locale) } ?? "" }

    /// "Bank of Canada, Nov 13, 2026"
    var sourceText: String {
        guard let latest = latestSeries?.latest else { return "" }
        return L10n.format("detail.source", Formatters.day(latest.date, locale: locale))
    }

    /// "High 1.4102 · Low 1.3781" for the chosen range.
    var rangeSummary: String {
        guard let history, let high = history.highest, let low = history.lowest else { return "" }
        return L10n.format("detail.highLow", Formatters.rate(high, locale: locale), Formatters.rate(low, locale: locale))
    }

    var isFavourite: Bool { favourites.isFavourite(currency.code) }

    func toggleFavourite() {
        favourites.toggle(currency.code)
        onChange?()
    }

    func select(_ range: Range) async {
        self.range = range
        await loadHistory()
    }

    func loadHistory() async {
        chart = .loading
        do {
            let series = try await store.repository.history(for: currency, count: range.count)
            history = series
            chart = .loaded(series.observations.map {
                ChartPoint(date: $0.date, value: NSDecimalNumber(decimal: $0.value).doubleValue)
            })
        } catch {
            history = nil
            chart = .failed((error as? RatesError ?? .offline).message)
        }
    }
}

/// One point on the chart. Double is fine here: it only decides where a dot is drawn.
struct ChartPoint: Identifiable, Equatable {
    let date: Date
    let value: Double
    var id: Date { date }
}
