import CoreLocation
import Foundation

struct Spot: Identifiable, Codable, Hashable, Sendable {
    var id: String
    var name: String
    var category: SpotCategory
    var latitude: Double
    var longitude: Double
    var savedAt: Date
    var status: SpotStatus
    var parkedDurationMs: Int?

    init(
        id: String,
        name: String,
        category: SpotCategory,
        latitude: Double,
        longitude: Double,
        savedAt: Date,
        status: SpotStatus = .none,
        parkedDurationMs: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.savedAt = savedAt
        self.status = status
        self.parkedDurationMs = parkedDurationMs
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isCar: Bool {
        id == StorageKeys.carId || category == .car
    }

    var isParking: Bool {
        status == .parking || (id == StorageKeys.carId && status != .found)
    }

    var isFound: Bool { status == .found }

    var parkedDuration: TimeInterval {
        if let parkedDurationMs {
            return Double(parkedDurationMs) / 1000
        }
        let parts = id.split(separator: "_").map(String.init)
        if parts.count >= 4, let start = Int(parts[2]), let end = Int(parts[3]), end >= start {
            return Double(end - start) / 1000
        }
        return Date().timeIntervalSince(savedAt)
    }
}

struct AppSettings: Codable, Equatable {
    var themeMode: AppThemeMode = .system
    var localeCode: String?
    var favoriteSpotId: String?
    var hasCompletedOnboarding: Bool = false
    var carDistanceNotificationEnabled: Bool = true
}

enum StorageKeys {
    static let carId = "car"
    static let appGroupId = "group.ios.dalely.app"
    static let widgetCarLat = "car_lat"
    static let widgetCarLng = "car_lng"
    static let widgetCarSavedAt = "car_saved_at"
    static let widgetFavId = "fav_id"
    static let widgetFavName = "fav_name"
    static let widgetFavCategory = "fav_category"
    static let widgetFavLat = "fav_lat"
    static let widgetFavLng = "fav_lng"
    static let widgetUserLat = "user_lat"
    static let widgetUserLng = "user_lng"
    static let widgetLabelMyCar = "label_my_car"
    static let widgetLabelPark = "label_park"
    static let widgetLabelFindCar = "label_find_car"
    static let widgetLabelNoCar = "label_no_car"
    static let widgetLabelNoFavorite = "label_no_favorite"
    static let widgetIsRtl = "is_rtl"
    static let uriScheme = "feen"
    static let uriSchemeDalely = "dalely"
}

enum AppLinks {
    static let website = "https://dalely.firebaseapp.com/"
    static let privacyPolicy = "https://dalely.firebaseapp.com/#privacy"
    static let whatsApp = "https://wa.me/201123225592"
    static let supportEmail = "salem.dev.77@gmail.com"
    static let appStore = "https://apps.apple.com/app/id6826521702"
    static let appleAppId = "6826521702"
}

struct SnackMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    var undoSpot: Spot?
}
