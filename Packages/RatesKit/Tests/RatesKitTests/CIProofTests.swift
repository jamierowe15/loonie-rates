import XCTest

/// Deliberately broken. This branch only proves CI blocks a failing test; it is never merged.
final class CIProofTests: XCTestCase {
    func testCIMustRejectThisBrokenTest() {
        XCTAssertEqual(1 + 1, 3)
    }
}
