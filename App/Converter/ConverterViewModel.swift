import Foundation
import RatesKit

@MainActor
final class ConverterViewModel {
    var onChange: (() -> Void)?

    private(set) var currency: Currency = Currency.withCode("USD") ?? Currency.all[0]
    private(set) var direction: ConversionDirection = .fromCAD
    var amountText = "100" {
        didSet { onChange?() }
    }

    private let store: RatesStore
    private let locale: Locale

    init(store: RatesStore, locale: Locale = .current) {
        self.store = store
        self.locale = locale
        store.observe { [weak self] in self?.onChange?() }
    }

    var title: String { L10n.text("converter.title") }
    var currencies: [Currency] { Currency.all }

    private var input: Currency { direction == .fromCAD ? .cad : currency }
    private var output: Currency { direction == .fromCAD ? currency : .cad }

    /// "CAD → USD" and "USD → CAD" for the direction switch.
    var directionTitles: [String] {
        ["CAD → \(currency.code)", "\(currency.code) → CAD"]
    }

    var amountPlaceholder: String { L10n.format("converter.amount.placeholder", input.code) }
    var amountLabel: String { L10n.format("converter.amount.label", input.localizedName) }
    var currencyButtonTitle: String { "\(currency.flag)  \(currency.code) · \(currency.localizedName)" }

    private var rate: Decimal? { store.series(for: currency.code)?.latest?.value }

    /// The big answer: "US$71.54", or a sentence explaining why there's no answer.
    var resultText: String {
        guard let rate else { return L10n.text("converter.noRate") }
        let separator = locale.decimalSeparator?.first ?? "."
        guard let amount = AmountParser.parse(amountText, decimalSeparator: separator) else {
            return L10n.text("converter.invalid")
        }
        guard let value = Converter.convert(amount, rate: rate, direction: direction, currency: currency) else {
            return L10n.text("converter.invalid")
        }
        return Formatters.money(value, currency: output, locale: locale)
    }

    /// "1 USD = 1.3978 CAD (Bank of Canada, Nov 13, 2026)"
    var rateNote: String {
        guard let latest = store.series(for: currency.code)?.latest else { return "" }
        return L10n.format("converter.rateNote", currency.code, Formatters.rate(latest.value, locale: locale),
                           Formatters.day(latest.date, locale: locale))
    }

    func select(_ currency: Currency) {
        self.currency = currency
        onChange?()
    }

    func setDirection(_ direction: ConversionDirection) {
        self.direction = direction
        onChange?()
    }

    func swapDirection() {
        setDirection(direction == .fromCAD ? .toCAD : .fromCAD)
    }
}
