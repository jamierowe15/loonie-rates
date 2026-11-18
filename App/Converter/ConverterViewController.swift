import RatesKit
import UIKit

/// The Converter tab: type an amount, pick a currency from a menu, flip the direction.
final class ConverterViewController: UIViewController {
    private let viewModel: ConverterViewModel
    private let amountLabel = UILabel()
    private let amountField = UITextField()
    private let currencyButton = UIButton(configuration: .gray())
    private let directionControl = UISegmentedControl(items: ["", ""])
    private let resultLabel = UILabel()
    private let noteLabel = UILabel()

    init(viewModel: ConverterViewModel) {
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
        view.backgroundColor = .systemBackground
        layout()
        viewModel.onChange = { [weak self] in self?.render() }
        render()
    }

    private func layout() {
        amountLabel.font = .preferredFont(forTextStyle: .subheadline)
        amountLabel.adjustsFontForContentSizeCategory = true
        amountLabel.textColor = .secondaryLabel
        amountLabel.numberOfLines = 0

        amountField.text = viewModel.amountText
        amountField.font = .preferredFont(forTextStyle: .title2)
        amountField.adjustsFontForContentSizeCategory = true
        amountField.keyboardType = .decimalPad
        amountField.borderStyle = .roundedRect
        amountField.clearButtonMode = .whileEditing
        amountField.accessibilityIdentifier = "converter.amount"
        amountField.addAction(UIAction { [weak self] _ in
            self?.viewModel.amountText = self?.amountField.text ?? ""
        }, for: .editingChanged)
        // A "Done" button above the number pad, which has no return key of its own.
        let toolbar = UIToolbar()
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace),
                         UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
                             self?.view.endEditing(true)
                         })]
        toolbar.sizeToFit()
        amountField.inputAccessoryView = toolbar

        // A pull-down menu of currencies: tap the button, pick one. No picker wheel.
        currencyButton.showsMenuAsPrimaryAction = true
        currencyButton.accessibilityIdentifier = "converter.currency"
        currencyButton.configuration?.titleLineBreakMode = .byWordWrapping
        currencyButton.configuration?.image = UIImage(systemName: "chevron.up.chevron.down")
        currencyButton.configuration?.imagePlacement = .trailing
        currencyButton.configuration?.imagePadding = 8

        directionControl.accessibilityIdentifier = "converter.direction"
        directionControl.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.viewModel.setDirection(self.directionControl.selectedSegmentIndex == 0 ? .fromCAD : .toCAD)
        }, for: .valueChanged)

        resultLabel.font = UIFontMetrics(forTextStyle: .largeTitle)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 40, weight: .bold))
        resultLabel.adjustsFontForContentSizeCategory = true
        resultLabel.numberOfLines = 0
        resultLabel.accessibilityIdentifier = "converter.result"
        resultLabel.accessibilityTraits.insert(.updatesFrequently)

        noteLabel.font = .preferredFont(forTextStyle: .footnote)
        noteLabel.adjustsFontForContentSizeCategory = true
        noteLabel.textColor = .secondaryLabel
        noteLabel.numberOfLines = 0
        noteLabel.accessibilityIdentifier = "converter.rateNote"

        let stack = UIStackView(arrangedSubviews: [currencyButton, directionControl, amountLabel, amountField, resultLabel, noteLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(6, after: amountLabel)
        stack.setCustomSpacing(28, after: amountField)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // keyboardLayoutGuide: the scroll view ends where the keyboard begins.
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            amountField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
    }

    private func render() {
        currencyButton.configuration?.title = viewModel.currencyButtonTitle
        currencyButton.menu = UIMenu(children: viewModel.currencies.map { currency in
            UIAction(title: "\(currency.flag)  \(currency.code) · \(currency.localizedName)",
                     state: currency == viewModel.currency ? .on : .off) { [weak self] _ in
                self?.viewModel.select(currency)
            }
        })
        currencyButton.accessibilityLabel = L10n.format("converter.currency.a11y", viewModel.currency.localizedName)

        for (index, title) in viewModel.directionTitles.enumerated() {
            directionControl.setTitle(title, forSegmentAt: index)
        }
        directionControl.selectedSegmentIndex = viewModel.direction == .fromCAD ? 0 : 1

        amountLabel.text = viewModel.amountLabel
        amountField.placeholder = viewModel.amountPlaceholder
        amountField.accessibilityLabel = viewModel.amountLabel
        if amountField.text != viewModel.amountText { amountField.text = viewModel.amountText }
        resultLabel.text = viewModel.resultText
        noteLabel.text = viewModel.rateNote
    }
}
