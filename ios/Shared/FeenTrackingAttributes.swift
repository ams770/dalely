import ActivityKit
import Foundation

public struct DalelyTrackingAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    public var state: String
    public var distanceText: String
    public var detailText: String
    public var parkedText: String
    public var progress: Double
    public var isArrived: Bool
    public var onMapLabel: String
    public var foundLabel: String
    public var appName: String

    public init(
      state: String = "walking",
      distanceText: String,
      detailText: String,
      parkedText: String,
      progress: Double,
      isArrived: Bool = false,
      onMapLabel: String,
      foundLabel: String,
      appName: String
    ) {
      self.state = state
      self.distanceText = distanceText
      self.detailText = detailText
      self.parkedText = parkedText
      self.progress = progress
      self.isArrived = isArrived
      self.onMapLabel = onMapLabel
      self.foundLabel = foundLabel
      self.appName = appName
    }
  }

  public var carName: String

  public init(carName: String) {
    self.carName = carName
  }
}
