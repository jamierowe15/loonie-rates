import Foundation

/// What the cache file holds: the rates and when they were saved.
public struct CachedRates: Codable, Equatable, Sendable {
    public let savedAt: Date
    public let series: [RateSeries]
}

/// Saves the last good rates to a JSON file, so the app still shows something offline.
/// An actor: only one task at a time can read or write the file, so it can't be corrupted.
public actor RatesCache {
    private let fileURL: URL

    public init(directory: URL, fileName: String = "rates-cache.json") {
        fileURL = directory.appendingPathComponent(fileName)
    }

    /// The app's Caches folder. iOS may empty it when storage is low, which is fine for rates.
    public static func standard() -> RatesCache {
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return RatesCache(directory: folder)
    }

    public func save(_ series: [RateSeries], at date: Date = Date()) throws {
        let data = try JSONEncoder().encode(CachedRates(savedAt: date, series: series))
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() -> CachedRates? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(CachedRates.self, from: data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
