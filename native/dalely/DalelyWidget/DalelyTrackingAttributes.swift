import ActivityKit
import Foundation

struct DalelyTrackingAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var state: String
        var distanceText: String
        var detailText: String
        var parkedText: String
        var progress: Double
        var isArrived: Bool
        var onMapLabel: String
        var foundLabel: String
        var appName: String
    }

    var carName: String
}
