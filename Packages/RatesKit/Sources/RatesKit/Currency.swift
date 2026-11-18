import Foundation

/// A currency the Bank of Canada publishes a daily rate for, against the Canadian dollar.
public struct Currency: Hashable, Codable, Sendable, Identifiable {
    /// ISO 4217 code, for example "USD".
    public let code: String
    public let englishName: String
    public let frenchName: String
    /// Digits after the decimal point when showing an amount (the yen has none).
    public let decimals: Int

    public var id: String { code }

    /// The Valet series name: "FXUSDCAD" means "1 US dollar costs this many Canadian dollars".
    public var seriesName: String { "FX\(code)CAD" }

    public init(code: String, englishName: String, frenchName: String, decimals: Int = 2) {
        self.code = code
        self.englishName = englishName
        self.frenchName = frenchName
        self.decimals = decimals
    }

    /// The name in French when the language code is "fr", otherwise in English.
    public func name(languageCode: String?) -> String {
        languageCode == "fr" ? frenchName : englishName
    }
}

public extension Currency {
    /// The currencies the app shows, in display order.
    static let all: [Currency] = [
        Currency(code: "USD", englishName: "US dollar", frenchName: "Dollar américain"),
        Currency(code: "EUR", englishName: "Euro", frenchName: "Euro"),
        Currency(code: "GBP", englishName: "UK pound sterling", frenchName: "Livre sterling"),
        Currency(code: "JPY", englishName: "Japanese yen", frenchName: "Yen japonais", decimals: 0),
        Currency(code: "CNY", englishName: "Chinese renminbi", frenchName: "Renminbi chinois"),
        Currency(code: "AUD", englishName: "Australian dollar", frenchName: "Dollar australien"),
        Currency(code: "CHF", englishName: "Swiss franc", frenchName: "Franc suisse"),
        Currency(code: "MXN", englishName: "Mexican peso", frenchName: "Peso mexicain"),
        Currency(code: "INR", englishName: "Indian rupee", frenchName: "Roupie indienne"),
        Currency(code: "HKD", englishName: "Hong Kong dollar", frenchName: "Dollar de Hong Kong"),
        Currency(code: "NZD", englishName: "New Zealand dollar", frenchName: "Dollar néo-zélandais"),
        Currency(code: "SEK", englishName: "Swedish krona", frenchName: "Couronne suédoise"),
    ]

    static func withCode(_ code: String) -> Currency? {
        all.first { $0.code == code }
    }
}
