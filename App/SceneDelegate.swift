import UIKit

/// Builds the window for the app's one scene and hands it to the coordinator.
/// No storyboard: every screen is created in code.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let environment = AppEnvironment.make(arguments: ProcessInfo.processInfo.arguments)
        let coordinator = AppCoordinator(window: window, environment: environment)
        coordinator.start()
        self.window = window
        self.coordinator = coordinator
    }
}
