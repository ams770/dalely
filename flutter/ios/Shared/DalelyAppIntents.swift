import AppIntents
import Foundation

@available(iOS 17.0, *)
public struct ShowOnMapIntent: LiveActivityIntent {
  public static var title: LocalizedStringResource = "Show on map"
  public static var openAppWhenRun: Bool = true

  public init() {}

  public func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: "group.ios.dalely.app") ?? UserDefaults.standard
    defaults.set("SHOW_MAP", forKey: "pending_notification_action")
    defaults.set("car", forKey: "pending_notification_data")
    defaults.set(Int64(Date().timeIntervalSince1970 * 1000.0), forKey: "pending_notification_time")
    defaults.synchronize()
    return .result()
  }
}

@available(iOS 17.0, *)
public struct FoundCarIntent: LiveActivityIntent {
  public static var title: LocalizedStringResource = "Found car"
  public static var openAppWhenRun: Bool = true

  public init() {}

  public func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: "group.ios.dalely.app") ?? UserDefaults.standard
    defaults.set("FOUND_CAR", forKey: "pending_notification_action")
    defaults.set(Int64(Date().timeIntervalSince1970 * 1000.0), forKey: "pending_notification_time")
    defaults.synchronize()
    return .result()
  }
}
