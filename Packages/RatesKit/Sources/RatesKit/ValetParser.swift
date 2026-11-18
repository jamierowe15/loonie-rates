import Foundation

/// Turns the Bank of Canada Valet JSON into `RateSeries`.
///
/// The JSON looks like this. Each observation row has a date under "d" and one key per series.
/// A series can be missing from a row (a holiday in that country), so the keys are dynamic:
///
///     {
///       "seriesDetail": { "FXUSDCAD": { "label": "USD/CAD", "description": "..." } },
///       "observations": [
///         { "d": "2026-11-12", "FXUSDCAD": { "v": "1.3954" }, "FXEURCAD": { "v": "1.6201" } },
///         { "d": "2026-11-13", "FXUSDCAD": { "v": "1.3978" } }
///       ]
///     }
public enum ValetParser {
    public static func series(from data: Data, currencies: [Currency]) throws -> [RateSeries] {
        let response: ValetResponse
        do {
            response = try JSONDecoder().decode(ValetResponse.self, from: data)
        } catch {
            throw RatesError.decoding(String(describing: error))
        }
        let posix = Locale(identifier: "en_US_POSIX")
        var result: [RateSeries] = []
        for currency in currencies {
            let observations = response.observations.compactMap { row -> RateObservation? in
                guard let text = row.values[currency.seriesName],
                      let value = Decimal(string: text, locale: posix) else { return nil }
                return RateObservation(day: row.day, value: value)
            }
            if !observations.isEmpty {
                result.append(RateSeries(currency: currency, observations: observations))
            }
        }
        return result
    }
}

/// The parts of the response we use. Unknown keys ("terms", "dimension") are ignored.
struct ValetResponse: Decodable {
    let observations: [Row]

    struct Row: Decodable {
        let day: String
        let values: [String: String]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyKey.self)
            var day: String?
            var values: [String: String] = [:]
            for key in container.allKeys {
                if key.stringValue == "d" {
                    day = try container.decode(String.self, forKey: key)
                } else if let cell = try? container.decode(Cell.self, forKey: key), let value = cell.v {
                    values[key.stringValue] = value
                }
            }
            guard let day else {
                throw DecodingError.dataCorruptedError(
                    forKey: AnyKey(stringValue: "d"), in: container, debugDescription: "Observation without a date")
            }
            self.day = day
            self.values = values
        }
    }

    /// { "v": "1.3978" }
    struct Cell: Decodable {
        let v: String?
    }
}

/// A coding key made from any string, for JSON objects whose keys we don't know in advance.
struct AnyKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}
