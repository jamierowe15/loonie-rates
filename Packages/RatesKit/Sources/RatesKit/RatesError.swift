import Foundation

/// Everything that can go wrong while getting rates. Screens turn these into friendly text.
public enum RatesError: Error, Equatable, Sendable {
    /// No connection, a timeout, or the request was cancelled.
    case offline
    /// The server answered with a non-2xx HTTP status.
    case server(status: Int)
    /// The JSON wasn't in the shape we expected.
    case decoding(String)
    /// The answer was valid but held no rates for the currencies we asked for.
    case noData
}
