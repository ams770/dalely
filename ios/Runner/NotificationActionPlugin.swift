import Flutter
import Foundation
import UIKit

@objc public class NotificationActionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  @objc public static let shared = NotificationActionPlugin()

  public static let methodChannelName = "feen/notification_actions"
  public static let eventChannelName = "feen/notification_actions/events"
  public static let appGroupId = "group.com.dalely.app"
  public static let keyPendingAction = "pending_notification_action"
  public static let keyPendingTime = "pending_notification_time"
  public static let keyPendingData = "pending_notification_data"

  private var eventSink: FlutterEventSink?
  private var initialAction: [String: Any]?
  private var isRegistered = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    NotificationActionPlugin.shared.register(with: registrar.messenger())
  }

  @objc public func register(with messenger: FlutterBinaryMessenger) {
    guard !isRegistered else { return }
    isRegistered = true

    let methodChannel = FlutterMethodChannel(name: Self.methodChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handle(call, result: result)
    }

    let eventChannel = FlutterEventChannel(name: Self.eventChannelName, binaryMessenger: messenger)
    eventChannel.setStreamHandler(self)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInitialAction":
      let initial = consumeInitialAction()
      result(initial)

    case "getPendingAction":
      let pending = readAndKeepPendingAction()
      result(pending)

    case "clearPendingAction":
      clearPendingAction()
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func consumeInitialAction() -> [String: Any]? {
    let action = initialAction
    initialAction = nil
    return action
  }

  private func getDefaults() -> UserDefaults {
    return UserDefaults(suiteName: Self.appGroupId) ?? UserDefaults.standard
  }

  public func recordPendingAction(
    action: String,
    timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000.0),
    data: String? = nil
  ) {
    let defaults = getDefaults()
    defaults.set(action, forKey: Self.keyPendingAction)
    defaults.set(timestamp, forKey: Self.keyPendingTime)
    if let data = data {
      defaults.set(data, forKey: Self.keyPendingData)
    } else {
      defaults.removeObject(forKey: Self.keyPendingData)
    }
    defaults.synchronize()
  }

  public func readAndKeepPendingAction() -> [String: Any]? {
    let defaults = getDefaults()
    guard let action = defaults.string(forKey: Self.keyPendingAction) else {
      return nil
    }
    let time = defaults.object(forKey: Self.keyPendingTime) as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000.0)
    let data = defaults.string(forKey: Self.keyPendingData)
    var map: [String: Any] = [
      "action": action,
      "timestamp": time
    ]
    if let data = data {
      map["data"] = data
    }
    return map
  }

  public func clearPendingAction() {
    let defaults = getDefaults()
    defaults.removeObject(forKey: Self.keyPendingAction)
    defaults.removeObject(forKey: Self.keyPendingTime)
    defaults.removeObject(forKey: Self.keyPendingData)
    defaults.synchronize()
  }

  @objc public func handleUrl(_ url: URL) {
    guard let scheme = url.scheme?.lowercased(), scheme == "feen" else { return }

    let host = url.host?.lowercased() ?? ""
    var action: String?
    var data: String?

    if host == "map" || host == "car" || host == "on_map" {
      action = "SHOW_MAP"
      if host == "map" {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        data = components?.queryItems?.first(where: { $0.name == "spot" })?.value ?? "car"
      } else {
        data = "car"
      }
    } else if host == "found_car" || host == "done" {
      action = "FOUND_CAR"
      data = nil
    } else if host == "park" {
      action = "PARK"
      data = nil
    } else if host == "spot" {
      action = "SHOW_SPOT"
      data = url.pathComponents.dropFirst().first
    }

    guard let resolvedAction = action else { return }

    let timestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
    recordPendingAction(action: resolvedAction, timestamp: timestamp, data: data)

    // When marking car found, immediately stop tracking and dismiss the Live Activity
    if resolvedAction == "FOUND_CAR" {
      CarTrackingManager.shared.stopTracking()
    }

    dispatchAction(action: resolvedAction, timestamp: timestamp, data: data)
  }

  public func dispatchAction(action: String, timestamp: Int64, data: String? = nil) {
    var payload: [String: Any] = [
      "action": action,
      "timestamp": timestamp
    ]
    if let data = data {
      payload["data"] = data
    }

    if let sink = eventSink {
      sink(payload)
    } else {
      initialAction = payload
    }
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    if let initial = consumeInitialAction() {
      events(initial)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
