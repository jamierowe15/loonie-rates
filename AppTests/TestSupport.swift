import Foundation
@testable import LoonieRates

/// Fixed locales so tests give the same answer on every machine.
enum TestLocales {
    static let english = Locale(identifier: "en_CA")
    static let french = Locale(identifier: "fr_CA")
}

@MainActor
enum TestSupport {
    static func store(failing: Bool = false, cachedFirst: Bool = false) async -> RatesStore {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let cache = RatesCache(directory: folder)
        if cachedFirst {
            let stub = StubRatesProvider()
            try? await cache.save(Currency.all.map { stub.makeSeries($0, count: 5) }, at: Date(timeIntervalSince1970: 1_794_663_660))
        }
        return RatesStore(repository: RatesRepository(provider: StubRatesProvider(failing: failing), cache: cache))
    }

    static func favourites() -> FavouritesStore {
        let name = "tests-\(UUID().uuidString)"
        return FavouritesStore(defaults: UserDefaults(suiteName: name) ?? .standard)
    }
}
