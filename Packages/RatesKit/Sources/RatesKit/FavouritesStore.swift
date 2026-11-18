import Foundation

/// The currencies the person starred, saved in UserDefaults (small settings, not secrets).
public final class FavouritesStore {
    private let defaults: UserDefaults
    private let key = "favouriteCurrencyCodes"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Starts with US dollar and euro so the Favourites section isn't empty on first launch.
    public var codes: [String] {
        defaults.stringArray(forKey: key) ?? ["USD", "EUR"]
    }

    public func isFavourite(_ code: String) -> Bool {
        codes.contains(code)
    }

    public func toggle(_ code: String) {
        var current = codes
        if let index = current.firstIndex(of: code) {
            current.remove(at: index)
        } else {
            current.append(code)
        }
        defaults.set(current, forKey: key)
    }
}
