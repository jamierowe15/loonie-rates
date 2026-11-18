import Charts
import SwiftUI
import UIKit

/// The chart is SwiftUI (Swift Charts has no UIKit version). The detail screen embeds it with
/// UIHostingController, which is how UIKit and SwiftUI live side by side in real apps.
struct RateChartView: View {
    let state: RateDetailViewModel.ChartState
    let code: String

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
                    .accessibilityLabel(L10n.text("detail.chart.loading"))
            case .failed(let message):
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .loaded(let points):
                chart(points)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private func chart(_ points: [ChartPoint]) -> some View {
        Chart(points) { point in
            LineMark(
                x: .value(L10n.text("chart.axis.date"), point.date),
                y: .value(L10n.text("chart.axis.rate"), point.value)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(Color(uiColor: Theme.brand))
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .accessibilityLabel(L10n.format("detail.chart.label", code, String(points.count)))
    }
}
