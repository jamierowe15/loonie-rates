import XCTest

/// Launches the app with fake rates. `offline` shows saved rates; `french` switches language.
func launchApp(offline: Bool = false, french: Bool = false) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-uiTesting"]
    if offline { app.launchArguments.append("-offline") }
    if french || ProcessInfo.processInfo.environment["LANG_UNDER_TEST"] == "fr" {
        app.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_CA"]
    }
    app.launch()
    return app
}

/// Any element with this accessibility identifier, whatever its type.
func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
    app.descendants(matching: .any)[identifier]
}

/// Taps a tab by position, so tests work in English and French.
func openTab(_ app: XCUIApplication, _ index: Int) {
    app.tabBars.buttons.element(boundBy: index).tap()
}

extension XCUIElement {
    /// Deletes what's in a text field and types new text.
    func replaceText(_ text: String) {
        // Tap near the right edge so the cursor lands after the existing text.
        coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let current = (value as? String) ?? ""
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2))
        typeText(text)
    }
}

/// Slows tests down only while a demo is being recorded (TEST_RUNNER_DEMO_PACE=1).
func demoPause(_ seconds: UInt32 = 1) {
    if ProcessInfo.processInfo.environment["DEMO_PACE"] != nil { sleep(seconds) }
}

/// Where tests drop screenshots and reports on the Mac running the Simulator.
func evidenceFolder() -> URL? {
    guard let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else { return nil }
    let folder = URL(fileURLWithPath: home).appendingPathComponent("lab-shots")
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
}
