import ActivityKit
import CoreLocation
import Flutter
import Foundation

@objc public class CarTrackingManager: NSObject, CLLocationManagerDelegate, FlutterStreamHandler {
  @objc public static let shared = CarTrackingManager()

  private let methodChannelName = "feen/car_tracking"
  private let eventChannelName = "feen/car_tracking/events"

  private var locationManager: CLLocationManager?
  private var eventSink: FlutterEventSink?

  private var carLocation: CLLocation?
  private var carSpotId: String = ""
  private var carSavedAt: Date = Date()
  private var carName: String = "My car"
  private var isArabic: BooleanLiteralType = false

  private var startDistanceMeters: Double?
  private var isArrived: Bool = false
  private var arrivalTimer: Timer?

  private var currentActivity: Any? // Activity<FeenTrackingAttributes>
  private var isTracking = false

  private var lastUpdateTime: Date = .distantPast
  private var lastDisplayedDistance: String?
  private var lastDisplayedWalkMinutes: Int?
  private var lastState: String = "waitingForGps"
  private var isRegistered = false

  @objc public func register(with messenger: FlutterBinaryMessenger) {
    guard !isRegistered else { return }
    isRegistered = true
    let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call, result: result)
    }

    let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
    eventChannel.setStreamHandler(self)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      guard let args = call.arguments as? [String: Any],
            let lat = args["carLat"] as? Double,
            let lng = args["carLng"] as? Double else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing coordinates", details: nil))
        return
      }

      let spotId = args["spotId"] as? String ?? ""
      let savedAtMillis = args["carSavedAt"] as? Double ?? Date().timeIntervalSince1970 * 1000.0
      let name = args["carName"] as? String ?? "My car"
      let isAr = args["isArabic"] as? Bool ?? false

      let success = startTracking(
        latitude: lat,
        longitude: lng,
        spotId: spotId,
        savedAt: Date(timeIntervalSince1970: savedAtMillis / 1000.0),
        carName: name,
        isArabic: isAr
      )
      result(success)

    case "stop":
      stopTracking()
      result(nil)

    case "isRunning":
      result(isTracking)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func startTracking(
    latitude: Double,
    longitude: Double,
    spotId: String,
    savedAt: Date,
    carName: String,
    isArabic: Bool
  ) -> Bool {
    self.carLocation = CLLocation(latitude: latitude, longitude: longitude)
    self.carSpotId = spotId
    self.carSavedAt = savedAt
    self.carName = carName
    self.isArabic = isArabic
    self.startDistanceMeters = nil
    self.isArrived = false
    self.lastState = "waitingForGps"
    self.lastUpdateTime = .distantPast

    if locationManager == nil {
      let manager = CLLocationManager()
      manager.delegate = self
      self.locationManager = manager
    }

    guard let manager = locationManager else { return false }

    let status = manager.authorizationStatus
    if status == .denied || status == .restricted {
      NSLog("CarTrackingManager: Location permission is denied or restricted.")
      return false
    }
    if status == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }

    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    manager.distanceFilter = 5.0
    manager.allowsBackgroundLocationUpdates = true
    manager.showsBackgroundLocationIndicator = true
    manager.pausesLocationUpdatesAutomatically = false

    manager.startUpdatingLocation()
    isTracking = true

    startLiveActivity()

    dispatchTrackingEvent(
      state: "waitingForGps",
      distanceMeters: nil,
      walkMinutes: nil,
      progress: 0.0,
      isArabic: isArabic,
      isArrived: false
    )

    return true
  }

  public func stopTracking() {
    isTracking = false
    arrivalTimer?.invalidate()
    arrivalTimer = nil

    locationManager?.stopUpdatingLocation()
    locationManager?.showsBackgroundLocationIndicator = false

    endLiveActivity()

    dispatchTrackingEvent(
      state: "stopped",
      distanceMeters: nil,
      walkMinutes: nil,
      progress: 0.0,
      isArabic: isArabic,
      isArrived: false
    )
  }

  // MARK: - ActivityKit Live Activity

  private func startLiveActivity() {
    guard #available(iOS 16.2, *) else { return }

    endLiveActivity()

    let appName = isArabic ? "فين" : "Feen"
    let onMapLabel = isArabic ? "اعرض على الخريطة" : "Show on map"
    let foundLabel = isArabic ? "وجدتُ سيارتي" : "Found my car"
    let parkedText = formatParkedAgo(carSavedAt, isArabic: isArabic)

    var initialState = FeenTrackingAttributes.ContentState(
      state: "waitingForGps",
      distanceText: isArabic ? "جارٍ التحديد..." : "Locating...",
      detailText: isArabic ? "في انتظار GPS" : "Looking for location",
      parkedText: parkedText,
      progress: 0.0,
      isArrived: false,
      onMapLabel: onMapLabel,
      foundLabel: foundLabel,
      appName: appName
    )

    if let loc = locationManager?.location, let car = carLocation, loc.horizontalAccuracy > 0, loc.horizontalAccuracy <= 100 {
      let distance = loc.distance(from: car)
      let walkSeconds = distance / 1.4
      let walkMins = max(1, Int(ceil(walkSeconds / 60.0)))
      let arrived = distance <= 15.0 && loc.horizontalAccuracy <= 25.0
      self.isArrived = arrived
      self.startDistanceMeters = distance

      initialState = FeenTrackingAttributes.ContentState(
        state: arrived ? "arrived" : "walking",
        distanceText: formatDistance(distance, isArabic: isArabic),
        detailText: arrived ? (isArabic ? "أنت على بعد أقل من 15 م" : "You are within 15 m") : formatWalkTime(walkMins, isArabic: isArabic),
        parkedText: parkedText,
        progress: arrived ? 1.0 : 0.0,
        isArrived: arrived,
        onMapLabel: onMapLabel,
        foundLabel: arrived ? (isArabic ? "تم" : "Done") : foundLabel,
        appName: appName
      )
    }

    let attributes = FeenTrackingAttributes(carName: carName)

    do {
      let activity = try Activity<FeenTrackingAttributes>.request(
        attributes: attributes,
        content: .init(state: initialState, staleDate: nil)
      )
      self.currentActivity = activity
    } catch {
      NSLog("CarTrackingManager: Failed to start Live Activity: \(error)")
    }
  }

  private func updateLiveActivity(
    state: String,
    distanceMeters: Double,
    walkMinutes: Int,
    progress: Double
  ) {
    guard #available(iOS 16.2, *) else { return }
    guard let activity = currentActivity as? Activity<FeenTrackingAttributes> else { return }

    let appName = isArabic ? "فين" : "Feen"
    let onMapLabel = isArabic ? "اعرض على الخريطة" : "Show on map"
    let foundLabel = isArrived ? (isArabic ? "تم" : "Done") : (isArabic ? "وجدتُ سيارتي" : "Found it")
    let parkedText = formatParkedAgo(carSavedAt, isArabic: isArabic)

    let distanceText = formatDistance(distanceMeters, isArabic: isArabic)
    let detailText: String
    if isArrived {
      detailText = isArabic ? "أنت على بعد أقل من 15 م" : "You are within 15 m"
    } else {
      detailText = formatWalkTime(walkMinutes, isArabic: isArabic)
    }

    let updatedContentState = FeenTrackingAttributes.ContentState(
      state: state,
      distanceText: distanceText,
      detailText: detailText,
      parkedText: parkedText,
      progress: isArrived ? 1.0 : progress,
      isArrived: isArrived,
      onMapLabel: onMapLabel,
      foundLabel: foundLabel,
      appName: appName
    )

    Task {
      await activity.update(ActivityContent(state: updatedContentState, staleDate: nil))
    }
  }

  private func endLiveActivity() {
    guard #available(iOS 16.2, *) else { return }
    for activity in Activity<FeenTrackingAttributes>.activities {
      Task {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
    self.currentActivity = nil
  }

  // MARK: - CLLocationManagerDelegate

  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard isTracking, let latest = locations.last, let car = carLocation else { return }

    let distance = latest.distance(from: car)
    let accuracy = latest.horizontalAccuracy

    // Initial fix / 1.5x reset
    if startDistanceMeters == nil {
      if accuracy <= 25.0 || startDistanceMeters == nil {
        startDistanceMeters = distance
      }
    } else if let start = startDistanceMeters, distance > 1.5 * start {
      startDistanceMeters = distance
    }

    let startDist = startDistanceMeters ?? distance
    let progress = startDist > 0 ? min(max(1.0 - (distance / startDist), 0.0), 1.0) : 1.0

    // Arrival hysteresis
    if isArrived {
      if distance > 30.0 {
        isArrived = false
        arrivalTimer?.invalidate()
        arrivalTimer = nil
      }
    } else {
      if distance <= 15.0 && accuracy <= 25.0 {
        isArrived = true
        startArrivalTimer()
      }
    }

    let state = isArrived ? "arrived" : "walking"

    // Walk minutes (1.4 m/s)
    let seconds = distance / 1.4
    let minutes = seconds < 60.0 ? 0 : Int(ceil(seconds / 60.0))

    let formattedDist = formatDistance(distance, isArabic: isArabic)
    let now = Date()
    let timeSinceLast = now.timeIntervalSince(lastUpdateTime)

    let valueChanged = (formattedDist != lastDisplayedDistance) ||
                       (minutes != lastDisplayedWalkMinutes) ||
                       (state != lastState)

    let shouldUpdateLiveActivity = (timeSinceLast >= 5.0 && valueChanged) || (timeSinceLast >= 15.0)

    if shouldUpdateLiveActivity || lastUpdateTime == .distantPast {
      lastUpdateTime = now
      lastDisplayedDistance = formattedDist
      lastDisplayedWalkMinutes = minutes
      lastState = state

      updateLiveActivity(
        state: state,
        distanceMeters: distance,
        walkMinutes: minutes,
        progress: progress
      )
    }

    dispatchTrackingEvent(
      state: state,
      distanceMeters: distance,
      walkMinutes: minutes,
      progress: isArrived ? 1.0 : progress,
      isArabic: isArabic,
      isArrived: isArrived
    )
  }

  private func startArrivalTimer() {
    guard arrivalTimer == nil else { return }
    arrivalTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: false) { [weak self] _ in
      self?.stopTracking()
    }
  }

  // MARK: - FlutterStreamHandler

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  private func dispatchTrackingEvent(
    state: String,
    distanceMeters: Double?,
    walkMinutes: Int?,
    progress: Double,
    isArabic: Bool,
    isArrived: Bool
  ) {
    DispatchQueue.main.async { [weak self] in
      let map: [String: Any?] = [
        "state": state,
        "distanceMeters": distanceMeters,
        "walkMinutes": walkMinutes,
        "progress": progress,
        "isArabic": isArabic,
        "isArrived": isArrived
      ]
      self?.eventSink?(map)
    }
  }

  // MARK: - Formatters

  private func formatDistance(_ meters: Double, isArabic: Bool) -> String {
    let clamped = max(meters, 0.0)
    if clamped < 100.0 {
      let rounded = Int(round(clamped / 5.0) * 5)
      return "\(rounded) \(isArabic ? "م" : "m")"
    } else if clamped < 1000.0 {
      let rounded = Int(round(clamped / 10.0) * 10)
      if rounded >= 1000 {
        let km = String(format: "%.1f", Double(rounded) / 1000.0)
        return "\(km) \(isArabic ? "كم" : "km")"
      }
      return "\(rounded) \(isArabic ? "م" : "m")"
    } else {
      let km = String(format: "%.1f", clamped / 1000.0)
      return "\(km) \(isArabic ? "كم" : "km")"
    }
  }

  private func formatWalkTime(_ minutes: Int, isArabic: Bool) -> String {
    if minutes <= 0 {
      return isArabic ? "أقل من دقيقة" : "Less than a minute"
    }
    if isArabic {
      switch minutes {
      case 1: return "حوالي دقيقة سيرًا"
      case 2: return "حوالي دقيقتين سيرًا"
      case 3...10: return "حوالي \(minutes) دقائق سيرًا"
      default: return "حوالي \(minutes) دقيقة سيرًا"
      }
    } else {
      return minutes == 1 ? "About 1 min walk" : "About \(minutes) min walk"
    }
  }

  private func formatParkedAgo(_ date: Date, isArabic: Bool) -> String {
    let hours = Int(Date().timeIntervalSince(date) / 3600.0)
    if hours <= 0 {
      return isArabic ? "رُكنت حديثًا" : "Parked recently"
    }
    if isArabic {
      return "رُكنت منذ \(hours) س"
    } else {
      return "Parked \(hours) h ago"
    }
  }
}
