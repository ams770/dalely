import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyCn28rpLlFBLIVY8yM31OacJ3cwyYO8q60")
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
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    CarTrackingManager.shared.stopTracking()
    super.applicationWillTerminate(application)
  }
}
