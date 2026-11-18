import Foundation

/// Every piece of text on screen comes from Localizable.strings through here, so translating
/// the app means translating one file per language. Keys look like "rates.title".
enum L10n {
    static func text(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// Fills %@ placeholders, e.g. format("converter.rateNote", "1 USD", "1.3978 $").
    static func format(_ key: String, _ arguments: String...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments.map { $0 as CVarArg })
    }

    /// "en" or "fr": the language the app is actually showing (not the region setting).
    static var languageCode: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }
}
