import Foundation
// Re-export RatesKit so every file in the app (and the unit tests, through @testable import
// LoonieRates) can use Currency, RateSeries and friends without linking the package twice.
@_exported import RatesKit

/// The composition root: the one place that decides which real or fake parts the app uses.
@MainActor
struct AppEnvironment {
    let store: RatesStore
    let favourites: FavouritesStore
    /// Work to do before the first refresh (UI tests use it to fill the offline cache).
    let prepare: () async -> Void

    /// Launch arguments switch on test modes:
    ///   -uiTesting   fake rates (StubRatesProvider), fresh settings, a temporary cache
    ///   -offline     with -uiTesting: the network "fails" and saved rates are shown
    static func make(arguments: [String]) -> AppEnvironment {
        guard arguments.contains("-uiTesting") else {
            let repository = RatesRepository(provider: ValetClient(), cache: RatesCache.standard())
            return AppEnvironment(store: RatesStore(repository: repository), favourites: FavouritesStore(), prepare: {})
        }
        let offline = arguments.contains("-offline")
        let suite = "ui-tests"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let cache = RatesCache(directory: folder)
        let repository = RatesRepository(provider: StubRatesProvider(failing: offline), cache: cache)
        return AppEnvironment(
            store: RatesStore(repository: repository),
            favourites: FavouritesStore(defaults: defaults),
            prepare: {
                guard offline else { return }
                let stub = StubRatesProvider()
                let saved = Currency.all.map { stub.makeSeries($0, count: 5) }
                // 14 Nov 2026, 9:41 local-ish: a fixed time so screenshots never change.
                try? await cache.save(saved, at: Date(timeIntervalSince1970: 1_794_663_660))
            }
        )
    }
}
