import RatesKit
import UIKit

/// The Rates tab: a list of currencies with today's rate, built with a compositional list
/// layout and a diffable data source (UIKit's modern replacement for reloadData()).
final class RatesListViewController: UIViewController {
    typealias Section = RatesListViewModel.Section

    /// The same currency can be in Favourites and All, so an item is (section, code).
    struct Item: Hashable {
        let section: Section
        let code: String
    }

    var onSelect: ((Currency) -> Void)?

    private let viewModel: RatesListViewModel
    private let banner = UILabel()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>?
    private let searchController = UISearchController(searchResultsController: nil)

    init(viewModel: RatesListViewModel) {
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
        view.backgroundColor = .systemGroupedBackground
        configureBanner()
        configureCollectionView()
        configureSearch()
        configureDataSource()
        viewModel.onChange = { [weak self] in self?.render() }
        render()
    }

    // MARK: Layout

    private func configureBanner() {
        banner.accessibilityIdentifier = "rates.banner"
        banner.font = .preferredFont(forTextStyle: .footnote)
        banner.adjustsFontForContentSizeCategory = true
        banner.numberOfLines = 0
        banner.textAlignment = .center
        banner.textColor = .label
        banner.backgroundColor = .secondarySystemGroupedBackground
        banner.isHidden = true
    }

    private func configureCollectionView() {
        collectionView.accessibilityIdentifier = "rates.list"
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.refreshControl = UIRefreshControl(frame: .zero, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            Task { await self.viewModel.refresh() }
        })

        // A vertical stack: the offline banner (when shown) above the list.
        let stack = UIStackView(arrangedSubviews: [banner, collectionView])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = L10n.text("rates.search")
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.headerMode = .supplementary
            configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
                self?.swipeActions(at: indexPath)
            }
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
    }

    // MARK: Data

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { [weak self] cell, _, item in
            guard let self, let row = self.viewModel.row(for: item.code) else { return }
            // valueCell: name on the left, rate on the right. At very large text sizes UIKit
            // stacks them vertically by itself, so nothing is cut off.
            var content = UIListContentConfiguration.valueCell()
            content.text = row.title
            content.secondaryText = "\(row.rateText)  \(row.trendText)"
            content.secondaryTextProperties.color = Theme.color(for: row.trend)
            // Digits of equal width line the rates up; UIFontMetrics makes the font follow Dynamic Type.
            content.secondaryTextProperties.font = UIFontMetrics(forTextStyle: .body)
                .scaledFont(for: .monospacedDigitSystemFont(ofSize: 17, weight: .regular))
            content.secondaryTextProperties.adjustsFontForContentSizeCategory = true
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
            cell.accessibilityIdentifier = "rates.row.\(item.section == .favourites ? "fav" : "all").\(item.code)"
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = row.accessibilityLabel
            cell.accessibilityValue = row.accessibilityValue
            cell.accessibilityTraits = .button
            cell.accessibilityCustomActions = [self.favouriteAction(for: item.code)]
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader) { [weak self] header, _, indexPath in
            guard let self, let section = self.dataSource?.sectionIdentifier(for: indexPath.section) else { return }
            var content = UIListContentConfiguration.groupedHeader()
            content.text = self.viewModel.sectionTitle(section)
            content.textProperties.color = .secondaryLabel
            header.contentConfiguration = content
            header.accessibilityTraits = .header
        }

        let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        self.dataSource = dataSource
    }

    /// Draws the current state. The diffable data source works out which rows moved, appeared
    /// or vanished and animates only those.
    private func render() {
        banner.text = viewModel.bannerText.map { "  \($0)  " }
        banner.isHidden = viewModel.bannerText == nil
        if !viewModel.isRefreshing { collectionView.refreshControl?.endRefreshing() }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        for section in viewModel.visibleSections {
            snapshot.appendSections([section])
            snapshot.appendItems(viewModel.codes(in: section).map { Item(section: section, code: $0) }, toSection: section)
        }
        // Same items but new rates: ask the cells to redraw their content.
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        dataSource?.apply(snapshot, animatingDifferences: view.window != nil)
        setNeedsUpdateContentUnavailableConfiguration()
    }

    /// iOS 17's built-in loading, error and "no results" screens.
    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        switch viewModel.state {
        case .loading:
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
        case .failed(let message):
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.image = UIImage(systemName: "wifi.exclamationmark")
            configuration.text = L10n.text("rates.error.title")
            configuration.secondaryText = message
            var button = UIButton.Configuration.borderedProminent()
            button.title = L10n.text("action.retry")
            configuration.button = button
            configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in
                guard let self else { return }
                Task { await self.viewModel.refresh() }
            }
            contentUnavailableConfiguration = configuration
        case .loaded:
            if viewModel.visibleSections.isEmpty {
                var configuration = UIContentUnavailableConfiguration.search()
                configuration.text = L10n.text("rates.search.empty")
                contentUnavailableConfiguration = configuration
            } else {
                contentUnavailableConfiguration = nil
            }
        }
    }

    // MARK: Favourites

    private func favouriteTitle(for code: String) -> String {
        L10n.text(viewModel.isFavourite(code) ? "action.unfavourite" : "action.favourite")
    }

    /// Swipe left on a row to star or unstar it.
    private func swipeActions(at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return nil }
        let action = UIContextualAction(style: .normal, title: favouriteTitle(for: item.code)) { [weak self] _, _, done in
            self?.viewModel.toggleFavourite(item.code)
            done(true)
        }
        action.image = UIImage(systemName: viewModel.isFavourite(item.code) ? "star.slash" : "star")
        action.backgroundColor = Theme.brand
        return UISwipeActionsConfiguration(actions: [action])
    }

    /// The same thing for VoiceOver users, who can't swipe a row: swipe up or down to pick it.
    private func favouriteAction(for code: String) -> UIAccessibilityCustomAction {
        UIAccessibilityCustomAction(name: favouriteTitle(for: code)) { [weak self] _ in
            self?.viewModel.toggleFavourite(code)
            return true
        }
    }
}

extension RatesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource?.itemIdentifier(for: indexPath),
              let currency = viewModel.currency(for: item.code) else { return }
        onSelect?(currency)
    }
}

extension RatesListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text ?? ""
    }
}
