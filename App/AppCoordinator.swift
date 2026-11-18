import RatesKit
import UIKit

/// Coordinator pattern: view controllers never push other view controllers themselves.
/// They report "the person tapped USD" through a closure, and the coordinator decides what to
/// show. Screens stay reusable and navigation lives in one file.
@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let environment: AppEnvironment
    private let tabBarController = UITabBarController()
    private let ratesNavigation = UINavigationController()
    private var converter: ConverterViewModel?

    init(window: UIWindow, environment: AppEnvironment) {
        self.window = window
        self.environment = environment
    }

    func start() {
        let listModel = RatesListViewModel(store: environment.store, favourites: environment.favourites)
        let list = RatesListViewController(viewModel: listModel)
        list.onSelect = { [weak self] currency in self?.showDetail(for: currency) }
        ratesNavigation.viewControllers = [list]
        ratesNavigation.navigationBar.prefersLargeTitles = true
        ratesNavigation.tabBarItem = UITabBarItem(title: L10n.text("tab.rates"),
                                                  image: UIImage(systemName: "chart.line.uptrend.xyaxis"), tag: 0)

        let converterModel = ConverterViewModel(store: environment.store)
        converter = converterModel
        let converterNavigation = UINavigationController(rootViewController: ConverterViewController(viewModel: converterModel))
        converterNavigation.navigationBar.prefersLargeTitles = true
        converterNavigation.tabBarItem = UITabBarItem(title: L10n.text("tab.converter"),
                                                      image: UIImage(systemName: "arrow.left.arrow.right"), tag: 1)

        tabBarController.viewControllers = [ratesNavigation, converterNavigation]
        window.tintColor = Theme.brand
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()

        let store = environment.store
        let prepare = environment.prepare
        Task {
            await prepare()
            await store.refresh()
        }
    }

    private func showDetail(for currency: Currency) {
        let model = RateDetailViewModel(currency: currency, store: environment.store, favourites: environment.favourites)
        let detail = RateDetailViewController(viewModel: model)
        detail.onConvert = { [weak self] currency in self?.showConverter(for: currency) }
        ratesNavigation.pushViewController(detail, animated: true)
    }

    private func showConverter(for currency: Currency) {
        converter?.select(currency)
        tabBarController.selectedIndex = 1
    }
}
