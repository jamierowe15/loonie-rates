import Foundation
import RatesKit

/// The latest rates, shared by every screen. The list and the converter both read from it,
/// so one refresh updates both. Screens subscribe with `observe`.
@MainActor
final class RatesStore {
    enum Status: Equatable {
        case idle, loading, loaded, failed(RatesError)
    }

    private(set) var snapshot: RatesSnapshot?
    private(set) var status: Status = .idle
    let repository: RatesRepository
    private var observers: [() -> Void] = []

    init(repository: RatesRepository) {
        self.repository = repository
    }

    /// Calls `handler` now and after every change. (The screens live as long as the app,
    /// so there is no unsubscribe; a bigger app would return a token to cancel with.)
    func observe(_ handler: @escaping () -> Void) {
        observers.append(handler)
        handler()
    }

    func refresh() async {
        status = .loading
        notify()
        do {
            snapshot = try await repository.load()
            status = .loaded
        } catch {
            status = .failed(error as? RatesError ?? .offline)
        }
        notify()
    }

    func series(for code: String) -> RateSeries? {
        snapshot?.series.first { $0.currency.code == code }
    }

    private func notify() {
        observers.forEach { $0() }
    }
}
