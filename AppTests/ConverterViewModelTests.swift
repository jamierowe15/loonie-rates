import XCTest
@testable import LoonieRates

@MainActor
final class ConverterViewModelTests: XCTestCase {
    private var store: RatesStore?

    private func makeModel(_ locale: Locale = TestLocales.english) async -> ConverterViewModel {
        let store = await TestSupport.store()
        let model = ConverterViewModel(store: store, locale: locale)
        await store.refresh()
        self.store = store
        return model
    }

    func testConvertsCADToUSD() async throws {
        let model = await makeModel()
        model.amountText = "100"
        let usd = try XCTUnwrap(Currency.withCode("USD"))
        let rate = try XCTUnwrap(store?.series(for: "USD")?.latest?.value)
        let expected = try XCTUnwrap(Converter.convert(100, rate: rate, direction: .fromCAD, currency: usd))
        XCTAssertEqual(model.resultText, Formatters.money(expected, currency: usd, locale: TestLocales.english))
    }

    func testSwapDirectionGivesCanadianDollars() async {
        let model = await makeModel()
        model.swapDirection()
        XCTAssertEqual(model.direction, .toCAD)
        XCTAssertTrue(model.resultText.contains("$"), model.resultText)
        XCTAssertEqual(model.directionTitles, ["CAD → USD", "USD → CAD"])
    }

    func testSelectingYenShowsNoDecimals() async {
        let model = await makeModel()
        model.select(Currency.withCode("JPY") ?? Currency.all[0])
        XCTAssertFalse(model.resultText.contains("."), model.resultText)
    }

    func testInvalidAmountExplainsItself() async {
        let model = await makeModel()
        model.amountText = "12abc"
        XCTAssertEqual(model.resultText, L10n.text("converter.invalid"))
    }

    func testFrenchUsesACommaForDecimals() async {
        let model = await makeModel(TestLocales.french)
        model.amountText = "100,50"
        XCTAssertTrue(model.resultText.contains(","), model.resultText)
    }

    func testNoRatesYetSaysSo() async {
        let store = await TestSupport.store(failing: true)
        let model = ConverterViewModel(store: store, locale: TestLocales.english)
        XCTAssertEqual(model.resultText, L10n.text("converter.noRate"))
    }
}
