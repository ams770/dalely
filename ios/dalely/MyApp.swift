import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static weak var sharedEnv: AppEnvironment? {
        didSet {
            flushPendingActions()
        }
    }
    static var pendingAction: NotificationAction?

    enum NotificationAction {
        case onMap
        case foundCar
    }

    static func flushPendingActions() {
        guard let env = sharedEnv, let action = pendingAction else { return }
        pendingAction = nil
        DispatchQueue.main.async {
            switch action {
            case .onMap:
                env.openMap(spotId: StorageKeys.carId, onlyShow: true)
            case .foundCar:
                env.foundCar()
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        switch response.actionIdentifier {
        case "action_on_map", UNNotificationDefaultActionIdentifier:
            if let env = AppDelegate.sharedEnv {
                Task { @MainActor in
                    env.openMap(spotId: StorageKeys.carId, onlyShow: true)
                }
            } else {
                AppDelegate.pendingAction = .onMap
            }

        case "action_found_car":
            if let env = AppDelegate.sharedEnv {
                Task { @MainActor in
                    env.foundCar()
                }
            } else {
                AppDelegate.pendingAction = .foundCar
            }

        default:
            break
        }
    }
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var env: AppEnvironment

    init() {
        let environment = AppEnvironment()
        _env = State(initialValue: environment)
        AppDelegate.sharedEnv = environment
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(env)
                .preferredColorScheme(env.preferredColorScheme)
                .environment(\.layoutDirection, env.isRTL ? .rightToLeft : .leftToRight)
                .onAppear {
                    AppDelegate.sharedEnv = env
                    AppDelegate.flushPendingActions()
                }
                .onOpenURL { url in
                    DispatchQueue.main.async {
                        env.handleURL(url)
                    }
                }
        }
    }
}
