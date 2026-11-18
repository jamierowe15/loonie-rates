import Foundation
@testable import RatesKit

/// A trimmed copy of a real Valet response. FXEURCAD is missing on the 13th on purpose.
enum Fixtures {
    static let valetJSON = """
    {
      "terms": { "url": "https://www.bankofcanada.ca/terms/" },
      "seriesDetail": {
        "FXUSDCAD": { "label": "USD/CAD", "description": "US dollar to Canadian dollar daily exchange rate",
                      "dimension": { "key": "d", "name": "Date" } },
        "FXEURCAD": { "label": "EUR/CAD", "description": "European euro to Canadian dollar daily exchange rate",
                      "dimension": { "key": "d", "name": "Date" } }
      },
      "observations": [
        { "d": "2026-11-13", "FXUSDCAD": { "v": "1.3978" } },
        { "d": "2026-11-11", "FXUSDCAD": { "v": "1.3921" }, "FXEURCAD": { "v": "1.6150" } },
        { "d": "2026-11-12", "FXUSDCAD": { "v": "1.3954" }, "FXEURCAD": { "v": "1.6204" } }
      ]
    }
    """

    static var valetData: Data { Data(valetJSON.utf8) }

    static let usd = Currency.withCode("USD")!
    static let eur = Currency.withCode("EUR")!
    static let jpy = Currency.withCode("JPY")!

    static func decimal(_ text: String) -> Decimal {
        Decimal(string: text, locale: Locale(identifier: "en_US_POSIX"))!
    }

    static func series(_ currency: Currency, _ values: [(String, String)]) -> RateSeries {
        RateSeries(currency: currency, observations: values.compactMap { RateObservation(day: $0.0, value: decimal($0.1)) })
    }
}

/// Answers every request with a fixed result and remembers the URLs it was asked for.
final class FakeTransport: HTTPTransport, @unchecked Sendable {
    private let result: Result<(Data, Int), Error>
    private(set) var requested: [URL] = []

    init(_ result: Result<(Data, Int), Error>) {
        self.result = result
    }

    func get(_ url: URL) async throws -> (Data, Int) {
        requested.append(url)
        return try result.get()
    }
}

struct SomeNetworkError: Error {}

func temporaryFolder() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
