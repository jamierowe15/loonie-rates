import RatesKit
import SwiftUI
import UIKit

/// One currency: today's rate, the trend, a chart with 1M / 3M / 1Y ranges, and a button
/// that opens the converter. Laid out with a scrolling UIStackView and Auto Layout in code.
final class RateDetailViewController: UIViewController {
    var onConvert: ((Currency) -> Void)?

    private let viewModel: RateDetailViewModel
    private let rateLabel = UILabel()
    private let trendLabel = UILabel()
    private let sourceLabel = UILabel()
    private let rangeControl = UISegmentedControl()
    private let summaryLabel = UILabel()
    private let convertButton = UIButton(configuration: .borderedProminent())
    private lazy var chartHost = UIHostingController(rootView: RateChartView(state: .loading, code: viewModel.currency.code))

    init(viewModel: RateDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Built in code, not in a storyboard")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        layout()
        viewModel.onChange = { [weak self] in self?.render() }
        render()
        Task { await viewModel.loadHistory() }
    }

    private func layout() {
        style(rateLabel, .largeTitle, identifier: "detail.rate")
        rateLabel.font = UIFontMetrics(forTextStyle: .largeTitle)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 34, weight: .bold))
        style(trendLabel, .title3, identifier: "detail.change")
        style(sourceLabel, .footnote, identifier: "detail.source")
        sourceLabel.textColor = .secondaryLabel
        style(summaryLabel, .subheadline, identifier: "detail.highLow")
        summaryLabel.textColor = .secondaryLabel

        for range in RateDetailViewModel.Range.allCases {
            rangeControl.insertSegment(withTitle: range.title, at: range.rawValue, animated: false)
        }
        rangeControl.selectedSegmentIndex = viewModel.range.rawValue
        rangeControl.accessibilityIdentifier = "detail.range"
        rangeControl.addAction(UIAction { [weak self] _ in
            guard let self, let range = RateDetailViewModel.Range(rawValue: self.rangeControl.selectedSegmentIndex) else { return }
            Task { await self.viewModel.select(range) }
        }, for: .valueChanged)

        convertButton.configuration?.title = L10n.format("detail.convert", viewModel.currency.code)
        convertButton.configuration?.image = UIImage(systemName: "arrow.left.arrow.right")
        convertButton.configuration?.imagePadding = 8
        convertButton.configuration?.buttonSize = .large
        convertButton.accessibilityIdentifier = "detail.convert"
        convertButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onConvert?(self.viewModel.currency)
        }, for: .touchUpInside)

        // Child view controller containment: the SwiftUI chart becomes part of this screen.
        addChild(chartHost)
        chartHost.view.backgroundColor = .clear
        chartHost.view.accessibilityIdentifier = "detail.chart"

        let header = UIStackView(arrangedSubviews: [rateLabel, trendLabel, sourceLabel])
        header.axis = .vertical
        header.spacing = 4
        let stack = UIStackView(arrangedSubviews: [header, rangeControl, chartHost.view, summaryLabel, convertButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        chartHost.didMove(toParent: self)

        let margins = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            chartHost.view.heightAnchor.constraint(equalToConstant: 240),
        ])
    }

    private func style(_ label: UILabel, _ textStyle: UIFont.TextStyle, identifier: String) {
        label.font = .preferredFont(forTextStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityIdentifier = identifier
    }

    private func render() {
        rateLabel.text = viewModel.rateText
        trendLabel.text = viewModel.trendText
        trendLabel.textColor = Theme.color(for: viewModel.trend)
        trendLabel.accessibilityLabel = viewModel.spokenTrend
        sourceLabel.text = viewModel.sourceText
        summaryLabel.text = viewModel.rangeSummary
        summaryLabel.isHidden = viewModel.rangeSummary.isEmpty
        chartHost.rootView = RateChartView(state: viewModel.chart, code: viewModel.currency.code)

        let star = UIBarButtonItem(image: UIImage(systemName: viewModel.isFavourite ? "star.fill" : "star"),
                                   primaryAction: UIAction { [weak self] _ in self?.viewModel.toggleFavourite() })
        star.accessibilityLabel = L10n.text(viewModel.isFavourite ? "action.unfavourite" : "action.favourite")
        star.accessibilityIdentifier = "detail.favourite"
        navigationItem.rightBarButtonItem = star
    }
}
