import Foundation

/// Which way the money goes.
public enum ConversionDirection: String, Codable, Sendable, CaseIterable {
    /// Canadian dollars in, foreign currency out ("I have $100 CAD, how many euros?").
    case fromCAD
    /// Foreign currency in, Canadian dollars out ("This costs 80 euros, what is that in CAD?").
    case toCAD
}

/// Converts amounts with a Bank of Canada rate (CAD per 1 unit of the foreign currency).
public enum Converter {
    /// Returns nil for a zero or negative rate or a negative amount.
    public static func convert(_ amount: Decimal, rate: Decimal, direction: ConversionDirection,
                               currency: Currency) -> Decimal? {
        guard rate > 0, amount >= 0 else { return nil }
        switch direction {
        case .toCAD:
            return round(amount * rate, places: 2)
        case .fromCAD:
            return round(amount / rate, places: currency.decimals)
        }
    }

    /// Rounds half away from zero ("plain" rounding), the way a teller would: 0.005 -> 0.01.
    public static func round(_ value: Decimal, places: Int) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, places, .plain)
        return output
    }
}

/// Reads what a person types into an amount field.
public enum AmountParser {
    /// "1,234.56" (English) or "1 234,56" (French) -> 1234.56.
    /// Returns nil for letters, two decimal points, or nothing at all.
    public static func parse(_ text: String, decimalSeparator: Character = ".") -> Decimal? {
        let grouping: Set<Character> = [",", ".", " ", "\u{00A0}", "\u{202F}", "'", "$"]
        var cleaned = ""
        for character in text.trimmingCharacters(in: .whitespacesAndNewlines) {
            if character.isASCII && character.isNumber {
                cleaned.append(character)
            } else if character == decimalSeparator {
                cleaned.append(".")
            } else if grouping.contains(character) {
                continue
            } else {
                return nil
            }
        }
        guard !cleaned.isEmpty, cleaned != ".", cleaned.filter({ $0 == "." }).count <= 1 else { return nil }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }
}
