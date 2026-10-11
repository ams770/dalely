import AppIntents
import Foundation

@available(iOS 17.0, *)
public struct ShowOnMapIntent: LiveActivityIntent {
  public static var title: LocalizedStringResource = "Show on map"
  public static var openAppWhenRun: Bool = true

  public init() {}

  public func perform() async throws -> some IntentResult {
    return .result()
  }
}

@available(iOS 17.0, *)
public struct FoundCarIntent: LiveActivityIntent {
  public static var title: LocalizedStringResource = "Found car"
  public static var openAppWhenRun: Bool = true

  public init() {}

  public func perform() async throws -> some IntentResult {
    return .result()
  }
}
