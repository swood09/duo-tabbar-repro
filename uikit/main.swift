// iPhone Duo: UITabBarController's vertical floating bar is built empty when
// its tabs arrive after first display, in landscape on the inner display.
//
// Variables, read from the environment at launch (SIMCTL_CHILD_<NAME> via simctl):
//   TABS_DELAY  seconds after makeKeyAndVisible before `tabs` is set; -1 sets them
//               before the window is shown (how a typical UIKit app does it). Default 0.5.
//   EMBED       1 puts the tab bar controller inside a UINavigationController as a
//               child, as React Native (react-native-screens) does. Default 0.
//   MODE        tabSidebar | tabBar | automatic. Default tabSidebar.
//   MINIMIZE    never sets tabBarMinimizeBehavior = .never.
//   SIDEBAR_HIDDEN  1 sets sidebar.isHidden = true before the window is shown.
//   SELECT      1 re-selects the first tab right after the tabs are set.
//   APPEARANCE  1 gives the tab bar custom standard and scroll-edge appearances.
//   EMPTY_FIRST 1 sets an empty `tabs` before the window is shown.
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   configurationForConnecting session: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: nil, sessionRole: session.role)
    config.delegateClass = SceneDelegate.self
    return config
  }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    let env = ProcessInfo.processInfo.environment
    let delay = Double(env["TABS_DELAY"] ?? "0.5") ?? 0.5
    let embed = env["EMBED"] == "1"
    let mode: UITabBarController.Mode = switch env["MODE"] {
      case "tabBar": .tabBar
      case "automatic": .automatic
      default: .tabSidebar
    }

    let tabs = UITabBarController()
    tabs.mode = mode
    if env["MINIMIZE"] == "never" { tabs.tabBarMinimizeBehavior = .never }
    if env["SIDEBAR_HIDDEN"] == "1" { tabs.sidebar.isHidden = true }
    if env["APPEARANCE"] == "1" {
      let appearance = UITabBarAppearance()
      appearance.configureWithTransparentBackground()
      appearance.stackedLayoutAppearance.selected.iconColor = .systemRed
      appearance.stackedLayoutAppearance.normal.iconColor = .label
      tabs.tabBar.standardAppearance = appearance
      tabs.tabBar.scrollEdgeAppearance = appearance
      tabs.tabBar.tintColor = .systemRed
    }
    if env["EMPTY_FIRST"] == "1" { tabs.tabs = [] }
    let select = env["SELECT"] == "1"
    let install = {
      tabs.tabs = Self.makeTabs()
      if select { tabs.selectedTab = tabs.tabs.first }
    }

    let window = UIWindow(windowScene: scene as! UIWindowScene)
    if embed {
      let nav = UINavigationController(rootViewController: tabs)
      nav.setNavigationBarHidden(true, animated: false)
      window.rootViewController = nav
    } else {
      window.rootViewController = tabs
    }

    if delay < 0 { install() }
    window.makeKeyAndVisible()
    self.window = window
    if delay >= 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { install() }
    }
    NSLog("[repro] TABS_DELAY=%@ EMBED=%@ MODE=%@", "\(delay)", "\(embed)", "\(mode.rawValue)")
  }

  static func makeTabs() -> [UITab] {
    let symbols = ["house", "dot.radiowaves.left.and.right", "map", "bubble.left.and.bubble.right", "person"]
    return symbols.enumerated().map { i, symbol in
      UITab(title: "Tab \(i + 1)", image: UIImage(systemName: symbol), identifier: "tab\(i)") { _ in
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "Tab \(i + 1)"
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
          label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
          label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
        ])
        return vc
      }
    }
  }
}
