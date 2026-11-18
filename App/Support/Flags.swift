import Foundation

/// The Swift face of the Objective-C helper (and the thing unit tests call).
enum Flags {
    static func emoji(for currencyCode: String) -> String {
        LRFlagHelper.flag(forCurrencyCode: currencyCode)
    }
}
