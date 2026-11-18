import XCTest

/// Runs Xcode's accessibility audit (the same checks as Accessibility Inspector) on every
/// screen and writes a report. Set TEST_RUNNER_STRICT_A11Y=1 to fail on any issue.
final class AccessibilityAuditTests: XCTestCase {
    private var rows: [String] = []

    func testAuditEveryScreen() throws {
        let app = launchApp()
        let usd = element(app, "rates.row.fav.USD")
        XCTAssertTrue(usd.waitForExistence(timeout: 10))
        audit(app, screen: "Rates")

        usd.tap()
        XCTAssertTrue(app.staticTexts["detail.highLow"].waitForExistence(timeout: 10))
        audit(app, screen: "Rate detail")

        openTab(app, 1)
        XCTAssertTrue(app.staticTexts["converter.result"].waitForExistence(timeout: 5))
        audit(app, screen: "Converter")

        app.terminate()
        let offline = launchApp(offline: true)
        XCTAssertTrue(offline.staticTexts["rates.banner"].waitForExistence(timeout: 10))
        audit(offline, screen: "Rates (offline)")

        writeReport()
        if ProcessInfo.processInfo.environment["STRICT_A11Y"] == "1" {
            XCTAssertFalse(rows.contains { !$0.contains("| Pass |") }, "The accessibility audit found issues")
        }
    }

    private func audit(_ app: XCUIApplication, screen: String) {
        var issues: [String] = []
        do {
            try app.performAccessibilityAudit { issue in
                issues.append(issue.compactDescription)
                return true // record it instead of failing the test
            }
        } catch {
            issues.append("The audit couldn't run: \(error.localizedDescription)")
        }
        if issues.isEmpty {
            rows.append("| \(screen) | Pass | - |")
        } else {
            let detail = issues.map { $0.replacingOccurrences(of: "|", with: "/") }.joined(separator: "<br>")
            rows.append("| \(screen) | \(issues.count) issue(s) | \(detail) |")
        }
    }

    private func writeReport() {
        let report = (["| Screen | Result | Details |", "|---|---|---|"] + rows).joined(separator: "\n") + "\n"
        let attachment = XCTAttachment(string: report)
        attachment.name = "a11y-audit.md"
        attachment.lifetime = .keepAlways
        add(attachment)
        if let folder = evidenceFolder() {
            try? report.write(to: folder.appendingPathComponent("a11y-audit.md"), atomically: true, encoding: .utf8)
        }
    }
}
