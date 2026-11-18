# Day 1: RatesKit

## Goal
Put every piece of logic that isn't a screen into a Swift package, test it, and run the
tests on GitHub's Mac and Linux machines on every push.

## What's in the package
| File | Job |
|---|---|
| `Currency.swift` | The 12 currencies, with English and French names and the Valet series name |
| `RateSeries.swift` | One currency's rates over time; change, percent change, trend, high and low |
| `ValetParser.swift` | Decodes the Bank of Canada JSON, whose keys change with each request |
| `HTTPTransport.swift` | A protocol for "GET this URL", plus the real URLSession version |
| `ValetClient.swift` | Builds the Valet URLs and turns HTTP failures into `RatesError` |
| `Converter.swift` | Decimal money maths and parsing typed amounts in English or French |
| `RatesCache.swift` | An actor that saves the last good rates to a JSON file |
| `RatesRepository.swift` | Network first, cache as a fallback; the only thing screens call |
| `FavouritesStore.swift` | Starred currencies in UserDefaults |
| `StubRatesProvider.swift` | Repeatable fake rates for UI tests and screenshots |

## Decisions
- **Decimal, not Double, for money.** `0.1 + 0.2` is `0.30000000000000004` as a Double. A test proves Decimal gets 0.3.
- **The API behind a protocol.** Tests use `FakeTransport`, so they run in milliseconds, offline, with any HTTP status we want.
- **Linux CI.** Running the same tests on Linux proves the package has no hidden iOS dependency.

## Proof
- `swift test` in `Packages/RatesKit`: 30+ tests across parsing, maths, the client, the cache and the repository.
- CI jobs `packages` (macOS, with a 70% coverage gate) and `packages-linux`.
