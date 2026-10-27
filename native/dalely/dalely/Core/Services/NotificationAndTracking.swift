import ActivityKit
import CoreLocation
import UserNotifications
import WidgetKit

enum AppNotifications {
    static let parkingId = "1001"
    static let arrivalId = "1002"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        let onMap = UNNotificationAction(identifier: "action_on_map", title: "On map", options: [.foreground])
        let found = UNNotificationAction(identifier: "action_found_car", title: "Found it", options: [.foreground])
        let category = UNNotificationCategory(identifier: "PARKING", actions: [onMap, found], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func showParking(distanceText: String, l10n: L10n) {
        let content = UNMutableNotificationContent()
        content.title = l10n.t("notificationParkingTitle")
        content.body = l10n.format("notificationDistance", ["distance": distanceText])
        content.categoryIdentifier = "PARKING"
        content.sound = .default
        let request = UNNotificationRequest(identifier: parkingId, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelParking() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [parkingId])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [parkingId])
    }

    static func showArrival(l10n: L10n) {
        let content = UNMutableNotificationContent()
        content.title = l10n.t("carArrivalTitle")
        content.body = l10n.t("carArrivalMessage")
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: arrivalId, content: content, trigger: nil))
    }
}

enum HomeWidgetBridge {
    static func sync(car: Spot?, favorite: Spot?, user: CLLocationCoordinate2D?, l10n: L10n) {
        let defaults = UserDefaults(suiteName: StorageKeys.appGroupId) ?? .standard
        if let car {
            defaults.set(car.latitude, forKey: StorageKeys.widgetCarLat)
            defaults.set(car.longitude, forKey: StorageKeys.widgetCarLng)
            defaults.set(car.savedAt.timeIntervalSince1970, forKey: StorageKeys.widgetCarSavedAt)
        } else {
            defaults.removeObject(forKey: StorageKeys.widgetCarLat)
            defaults.removeObject(forKey: StorageKeys.widgetCarLng)
            defaults.removeObject(forKey: StorageKeys.widgetCarSavedAt)
        }
        if let favorite {
            defaults.set(favorite.id, forKey: StorageKeys.widgetFavId)
            defaults.set(favorite.name, forKey: StorageKeys.widgetFavName)
            defaults.set(favorite.category.rawValue, forKey: StorageKeys.widgetFavCategory)
            defaults.set(favorite.latitude, forKey: StorageKeys.widgetFavLat)
            defaults.set(favorite.longitude, forKey: StorageKeys.widgetFavLng)
        } else {
            [StorageKeys.widgetFavId, StorageKeys.widgetFavName, StorageKeys.widgetFavCategory, StorageKeys.widgetFavLat, StorageKeys.widgetFavLng].forEach {
                defaults.removeObject(forKey: $0)
            }
        }
        if let user {
            defaults.set(user.latitude, forKey: StorageKeys.widgetUserLat)
            defaults.set(user.longitude, forKey: StorageKeys.widgetUserLng)
        }
        defaults.set(l10n.t("myCar"), forKey: StorageKeys.widgetLabelMyCar)
        defaults.set(l10n.t("widgetPark"), forKey: StorageKeys.widgetLabelPark)
        defaults.set(l10n.t("widgetFindCar"), forKey: StorageKeys.widgetLabelFindCar)
        defaults.set(l10n.t("widgetNoCar"), forKey: StorageKeys.widgetLabelNoCar)
        defaults.set(l10n.t("widgetNoFavorite"), forKey: StorageKeys.widgetLabelNoFavorite)
        defaults.set(l10n.isArabic, forKey: StorageKeys.widgetIsRtl)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

@Observable
final class CarTrackingService {
    private var activity: Activity<DalelyTrackingAttributes>?
    var isTracking = false
    var isArrived = false
    var startDistance: Double = 0
    var currentDistance: Double = 0
    var trackedCar: Spot?

    func start(car: Spot, current: CLLocationCoordinate2D?, l10n: L10n) {
        trackedCar = car
        isTracking = true
        isArrived = false
        if let current {
            startDistance = CarTrackingCalculator.calculateDistance(from: current, to: car.coordinate)
            currentDistance = startDistance
        }
        Task { await startActivity(car: car, l10n: l10n) }
    }

    func update(user: CLLocation, l10n: L10n) {
        guard isTracking, let car = trackedCar else { return }
        currentDistance = CarTrackingCalculator.calculateDistance(from: user.coordinate, to: car.coordinate)
        if CarTrackingCalculator.shouldResetStartDistance(currentDistance: currentDistance, startDistance: startDistance) {
            startDistance = currentDistance
        }
        isArrived = CarTrackingCalculator.checkArrival(
            distance: currentDistance,
            horizontalAccuracy: user.horizontalAccuracy,
            currentlyArrived: isArrived
        )
        Task { await updateActivity(l10n: l10n) }
    }

    func stop() {
        isTracking = false
        isArrived = false
        trackedCar = nil
        Task { await activity?.end(nil, dismissalPolicy: .immediate) }
        activity = nil
    }

    @available(iOS 16.2, *)
    private func startActivity(car: Spot, l10n: L10n) async {
        let attributes = DalelyTrackingAttributes(carName: car.name.isEmpty ? l10n.t("myCar") : car.name)
        let state = contentState(l10n: l10n)
        do {
            activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))
        } catch {
            activity = nil
        }
    }

    private func updateActivity(l10n: L10n) async {
        let state = contentState(l10n: l10n)
        await activity?.update(.init(state: state, staleDate: nil))
    }

    private func contentState(l10n: L10n) -> DalelyTrackingAttributes.ContentState {
        let minutes = CarTrackingCalculator.calculateWalkMinutes(currentDistance)
        let distanceText = isTracking && currentDistance == 0 && startDistance == 0
            ? l10n.t("carTrackingLookingForLocation")
            : CarTrackingCalculator.formatDistance(currentDistance, isArabic: l10n.isArabic)
        let detail = isArrived ? l10n.t("carTrackingArrivedBody") : l10n.carTrackingAboutMinutes(minutes)
        let progress = CarTrackingCalculator.calculateProgress(currentDistance: currentDistance, startDistance: startDistance)
        return .init(
            state: isArrived ? "arrived" : "walking",
            distanceText: isArrived ? l10n.t("carTrackingArrivedTitle") : l10n.format("carTrackingWalkingTitle", ["distance": distanceText]),
            detailText: detail,
            parkedText: trackedCar.map { TimeAgoFormatter.format($0.savedAt, l10n: l10n) } ?? "",
            progress: progress,
            isArrived: isArrived,
            onMapLabel: l10n.t("onMap"),
            foundLabel: l10n.t("foundMyCar"),
            appName: l10n.t("appTitle")
        )
    }
}

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
