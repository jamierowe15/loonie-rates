import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking // URLSession lives here on Linux
#endif

/// The one thing the client needs from the network: GET a URL, return the body and status.
/// A protocol, so tests can hand in a fake and never touch the real internet.
public protocol HTTPTransport: Sendable {
    func get(_ url: URL) async throws -> (Data, Int)
}

/// The real transport, built on URLSession.
public struct URLSessionTransport: HTTPTransport, @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(_ url: URL) async throws -> (Data, Int) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // A continuation bridges URLSession's older completion-handler API into async/await.
        // It works on every platform, including Linux's Foundation.
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                continuation.resume(returning: (data ?? Data(), status))
            }
            task.resume()
        }
    }
}
