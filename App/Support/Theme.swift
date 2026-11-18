import RatesKit
import UIKit

/// The app's colours. Each one has a light and a dark version, and every text colour has at
/// least 4.5:1 contrast with the background (the WCAG AA rule for normal text).
enum Theme {
    /// Maple red. The system's default blue is too faint for small text on white.
    static let brand = dynamic(light: (0.75, 0.10, 0.12), dark: (1.00, 0.45, 0.45))
    /// Rates going up. Darker than .systemGreen, which fails contrast on white.
    static let up = dynamic(light: (0.07, 0.42, 0.18), dark: (0.45, 0.88, 0.55))
    static let down = dynamic(light: (0.70, 0.11, 0.11), dark: (1.00, 0.52, 0.52))
    static let flat = UIColor.secondaryLabel

    static func color(for trend: Trend) -> UIColor {
        switch trend {
        case .up: return up
        case .down: return down
        case .flat: return flat
        }
    }

    private static func dynamic(light: (CGFloat, CGFloat, CGFloat), dark: (CGFloat, CGFloat, CGFloat)) -> UIColor {
        UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        }
    }
}
