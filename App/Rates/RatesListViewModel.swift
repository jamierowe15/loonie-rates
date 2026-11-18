import Foundation
import RatesKit

/// MVVM: the view model holds the screen's state and logic; the view controller only draws it.
/// No UIKit import here, so it is tested with plain unit tests.
@MainActor
final class RatesListViewModel {
    enum Section: Int, CaseIterable, Hashable {
        case favourites, all
    }

    enum State: Equatable {
        case loading, loaded, failed(String)
    }

    /// Everything one row shows, already formatted.
    struct Row: Hashable {
        let code: String
        let title: String
        let rateText: String
        let trendText: String
        let trend: Trend
        let accessibilityLabel: String
        let accessibilityValue: String
    }

    var onChange: (() -> Void)?
    var searchText = "" {
        didSet { onChange?() }
    }

    private let store: RatesStore
    private let favourites: FavouritesStore
    private let locale: Locale

    init(store: RatesStore, favourites: FavouritesStore, locale: Locale = .current) {
        self.store = store
        self.favourites = favourites
        self.locale = locale
        store.observe { [weak self] in self?.onChange?() }
    }

    var title: String { L10n.text("rates.title") }

    /// Once any rates exist (live or saved) the list shows them; before that, a spinner or an error.
    var state: State {
        if store.snapshot != nil { return .loaded }
        if case .failed(let error) = store.status { return .failed(error.message) }
        return .loading
    }

    var isRefreshing: Bool { store.status == .loading }

    /// "Offline. Showing rates saved Nov 14, 2026 at 9:41 AM." or nil when live.
    var bannerText: String? {
        guard case .cached(let savedAt)? = store.snapshot?.source else { return nil }
        return L10n.format("rates.banner.offline", Formatters.dateTime(savedAt, locale: locale))
    }

    /// The codes in each section, after the search filter. Empty sections are left out.
    func codes(in section: Section) -> [String] {
        let all = (store.snapshot?.series ?? []).filter(matchesSearch).map(\.currency.code)
        switch section {
        case .favourites: return favourites.codes.filter { all.contains($0) }
        case .all: return all
        }
    }

    var visibleSections: [Section] {
        Section.allCases.filter { !codes(in: $0).isEmpty }
    }

    func sectionTitle(_ section: Section) -> String {
        L10n.text(section == .favourites ? "rates.section.favourites" : "rates.section.all")
    }

    func row(for code: String) -> Row? {
        guard let series = store.series(for: code) else { return nil }
        let currency = series.currency
        let rate = series.latest.map { Formatters.rate($0.value, locale: locale) } ?? "–"
        return Row(
            code: code,
            title: "\(currency.flag)  \(currency.localizedName)",
            rateText: rate,
            trendText: Formatters.trend(series, locale: locale),
            trend: series.trend,
            accessibilityLabel: "\(currency.localizedName), \(code)",
            accessibilityValue: L10n.format("a11y.rate", rate, Formatters.spokenTrend(series, locale: locale))
        )
    }

    func currency(for code: String) -> Currency? {
        store.series(for: code)?.currency
    }

    func isFavourite(_ code: String) -> Bool {
        favourites.isFavourite(code)
    }

    func toggleFavourite(_ code: String) {
        favourites.toggle(code)
        onChange?()
    }

    func refresh() async {
        await store.refresh()
    }

    private func matchesSearch(_ series: RateSeries) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        return series.currency.localizedName.localizedCaseInsensitiveContains(query)
            || series.currency.code.localizedCaseInsensitiveContains(query)
    }
}
