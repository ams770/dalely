import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if !engineBridge.pluginRegistry.hasPlugin("CarTracking"),
       let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CarTracking") {
      CarTrackingManager.shared.register(with: registrar.messenger())
    }
    if !engineBridge.pluginRegistry.hasPlugin("NotificationActions"),
       let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NotificationActions") {
      NotificationActionPlugin.shared.register(with: registrar.messenger())
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NotificationActionPlugin.shared.handleUrl(url)
    return super.application(app, open: url, options: options)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    CarTrackingManager.shared.stopTracking()
    super.applicationWillTerminate(application)
  }
}
