import CoreLocation
import SwiftUI
import UIKit

enum DetailPane: Equatable {
    case map
    case settings
    case parkingHistory
}

enum AppRoute: Equatable, Hashable {
    case map(spotId: String?, onlyShow: Bool)
    case saveSpot(lat: Double?, lng: Double?, name: String?, editingId: String?)
    case settings
    case parkingHistory
}

@Observable
final class AppEnvironment {
    var settings: AppSettings
    var spots: [Spot] = []
    var sortOrder: SpotSortOrder = .dateDesc
    var location = LocationService()
    var tracking = CarTrackingService()
    var snack: SnackMessage?
    var showArrival = false
    var pendingRoute: AppRoute?
    var path: [AppRoute] = []
    var detailPane: DetailPane = .map
    var searchQuery: String = ""
    var isSearchPresented: Bool = false
    var mapFocusSpotId: String?
    var mapOnlyShowSpotId: String?
    var saveDraft: SaveDraft?
    var lastProximityAway = false
    var isMapExpanded: Bool = false

    func toggleMapFullscreen() {
        isMapExpanded.toggle()
    }

    struct SaveDraft: Equatable {
        var latitude: Double?
        var longitude: Double?
        var name: String?
        var editingId: String?
    }

    init() {
        settings = LocalStore.loadSettings()
        spots = LocalStore.loadSpots()
        location.start()
        syncWidgets()
    }

    func reloadFromDisk() {
        let loaded = LocalStore.loadSpots()
        if loaded != spots {
            spots = loaded
            syncWidgets()
        }
    }

    var l10n: L10n {
        L10n(locale: resolvedLocale)
    }

    var resolvedLocale: Locale {
        if let code = settings.localeCode {
            return Locale(identifier: code)
        }
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        if language == "ar" { return Locale.current }
        return Locale(identifier: "en")
    }

    var isRTL: Bool { l10n.isArabic }
    var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }

    var palette: AppPalette {
        switch effectiveColorScheme {
        case .dark: .dark
        default: .light
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var systemColorScheme: ColorScheme = .light

    func updateSystemColorScheme(_ scheme: ColorScheme) {
        if self.systemColorScheme != scheme {
            self.systemColorScheme = scheme
        }
    }

    var effectiveColorScheme: ColorScheme {
        switch settings.themeMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return systemColorScheme
        }
    }

    var car: Spot? {
        spots.first { $0.id == StorageKeys.carId && $0.status != .found }
    }

    var savedSpots: [Spot] {
        let list = spots.filter { !$0.isFound && $0.id != StorageKeys.carId && $0.category != .car }
        return sort(list)
    }

    var parkingHistory: [Spot] {
        spots.filter { $0.status == .found || ($0.category == .car && $0.id != StorageKeys.carId) }
            .sorted { $0.savedAt > $1.savedAt }
    }

    var allSpots: [Spot] {
        (car.map { [$0] } ?? []) + savedSpots
    }

    var favoriteSpot: Spot? {
        guard let id = settings.favoriteSpotId else { return nil }
        return spots.first { $0.id == id }
    }

    func persist() {
        LocalStore.saveSpots(spots)
        LocalStore.saveSettings(settings)
        syncWidgets()
    }

    func syncWidgets() {
        HomeWidgetBridge.sync(car: car, favorite: favoriteSpot, user: location.coordinate, l10n: l10n)
    }

    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        persist()
    }

    func setTheme(_ mode: AppThemeMode) {
        settings.themeMode = mode
        persist()
    }

    func setLocale(_ code: String?) {
        settings.localeCode = code
        persist()
        syncWidgets()
    }

    func setCarTrackingEnabled(_ enabled: Bool) {
        settings.carDistanceNotificationEnabled = enabled
        persist()
        if !enabled { tracking.stop() }
    }

    func parkHere() {
        guard let coordinate = location.coordinate else {
            location.requestPermission()
            return
        }
        let carSpot = Spot(
            id: StorageKeys.carId,
            name: l10n.t("myCar"),
            category: .car,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            savedAt: Date(),
            status: .parking
        )
        spots.removeAll { $0.id == StorageKeys.carId }
        spots.append(carSpot)
        persist()
        AppNotifications.cancelParking()
        // Pinned Dynamic Island Live Activity
        tracking.start(car: carSpot, current: coordinate, l10n: l10n)
        Haptics.success()
    }

    func clearCar() {
        guard let current = car else { return }
        tracking.stop()
        AppNotifications.cancelParking()
        let now = Date()
        let history = Spot(
            id: "car_history_\(Int(current.savedAt.timeIntervalSince1970 * 1000))_\(Int(now.timeIntervalSince1970 * 1000))",
            name: current.name,
            category: .car,
            latitude: current.latitude,
            longitude: current.longitude,
            savedAt: current.savedAt,
            status: .found,
            parkedDurationMs: Int(now.timeIntervalSince(current.savedAt) * 1000)
        )
        spots.removeAll { $0.id == StorageKeys.carId }
        spots.append(history)
        persist()
        Haptics.success()
    }

    func restore(_ spot: Spot) {
        spots.removeAll { $0.id == spot.id }
        spots.append(spot)
        persist()
    }

    func saveSpot(name: String, category: SpotCategory, latitude: Double, longitude: Double, editingId: String?) {
        if category == .car {
            let carSpot = Spot(id: StorageKeys.carId, name: l10n.t("myCar"), category: .car, latitude: latitude, longitude: longitude, savedAt: Date(), status: .parking)
            spots.removeAll { $0.id == StorageKeys.carId }
            spots.append(carSpot)
            persist()
            Haptics.success()
            return
        }
        if let editingId, let index = spots.firstIndex(where: { $0.id == editingId }) {
            spots[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            spots[index].category = category
            spots[index].latitude = latitude
            spots[index].longitude = longitude
            persist()
            Haptics.success()
            return
        }
        let spot = Spot(
            id: newId(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            latitude: latitude,
            longitude: longitude,
            savedAt: Date()
        )
        spots.append(spot)
        persist()
        Haptics.success()
    }

    func deleteSpot(_ spot: Spot) {
        spots.removeAll { $0.id == spot.id }
        if settings.favoriteSpotId == spot.id {
            settings.favoriteSpotId = nil
        }
        persist()
        snack = SnackMessage(text: l10n.format("spotDeleted", ["name": spot.name]), undoSpot: spot)
    }

    func toggleFavorite(_ spot: Spot) {
        if settings.favoriteSpotId == spot.id {
            settings.favoriteSpotId = nil
        } else {
            settings.favoriteSpotId = spot.id
        }
        persist()
        Haptics.selection()
    }

    func clearParkingHistory() {
        let ids = Set(parkingHistory.map(\.id))
        spots.removeAll { ids.contains($0.id) }
        persist()
        Haptics.success()
    }

    func openDirections(for spot: Spot) {
        if settings.carDistanceNotificationEnabled, spot.isCar, let user = location.coordinate {
            let dist = CarTrackingCalculator.calculateDistance(from: user, to: spot.coordinate)
            if CarTrackingCalculator.isTooFar(dist) {
                openMap(spotId: spot.id, onlyShow: true)
                return
            }
            tracking.start(car: spot, current: user, l10n: l10n)
        }
        MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
    }

    func foundCar() {
        if car == nil {
            reloadFromDisk()
        }
        guard let current = car else {
            tracking.stop()
            AppNotifications.cancelParking()
            return
        }
        tracking.stop()
        AppNotifications.cancelParking()
        let now = Date()
        let history = Spot(
            id: "car_history_\(Int(current.savedAt.timeIntervalSince1970 * 1000))_\(Int(now.timeIntervalSince1970 * 1000))",
            name: current.name,
            category: .car,
            latitude: current.latitude,
            longitude: current.longitude,
            savedAt: current.savedAt,
            status: .found,
            parkedDurationMs: Int(now.timeIntervalSince(current.savedAt) * 1000)
        )
        spots.removeAll { $0.id == StorageKeys.carId }
        spots.append(history)
        persist()
        showArrival = false
        snack = SnackMessage(text: l10n.t("carFoundCelebration"), undoSpot: current)
        Haptics.success()
    }

    func updateProximity() {
        guard let car, let user = location.lastLocation else { return }
        if tracking.isTracking {
            tracking.update(user: user, l10n: l10n)
        } else {
            tracking.start(car: car, current: user.coordinate, l10n: l10n)
        }
    }

    func openMap(spotId: String? = nil, onlyShow: Bool = false) {
        mapFocusSpotId = nil
        mapFocusSpotId = spotId
        mapOnlyShowSpotId = onlyShow ? spotId : nil
        detailPane = .map
        if !isTwoPane {
            path.append(AppRoute.map(spotId: spotId, onlyShow: onlyShow))
        }
    }

    func openSaveSpot(lat: Double? = nil, lng: Double? = nil, name: String? = nil, editing: Spot? = nil) {
        saveDraft = SaveDraft(latitude: lat ?? editing?.latitude, longitude: lng ?? editing?.longitude, name: name ?? editing?.name, editingId: editing?.id)
        if !isTwoPane {
            path.append(AppRoute.saveSpot(lat: saveDraft?.latitude, lng: saveDraft?.longitude, name: saveDraft?.name, editingId: saveDraft?.editingId))
        } else {
            detailPane = .map
        }
    }

    func openSearch(query: String? = nil) {
        searchQuery = query ?? ""
        isSearchPresented = true
    }

    func openSettings() {
        if isTwoPane {
            detailPane = .settings
        } else {
            path.append(AppRoute.settings)
        }
    }

    func openParkingHistory() {
        if isTwoPane {
            detailPane = .parkingHistory
        } else {
            path.append(AppRoute.parkingHistory)
        }
    }

    func closeDetail() {
        detailPane = .map
        saveDraft = nil
        mapOnlyShowSpotId = nil
    }

    private var _isTwoPane: Bool?

    var isTwoPane: Bool {
        get {
            _isTwoPane ?? computeIsTwoPane()
        }
        set {
            _isTwoPane = newValue
        }
    }

    private func computeIsTwoPane() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windowWidth = scenes.first?.windows.first(where: { $0.isKeyWindow })?.bounds.width
            ?? scenes.first?.windows.first?.bounds.width
            ?? scenes.first?.screen.bounds.width
            ?? 0
        return windowWidth >= 700
    }

    func adaptLayout(toWide: Bool) {
        let previousMode = _isTwoPane
        self.isTwoPane = toWide
        if let previousMode, previousMode == toWide {
            return
        }

        if toWide {
            // Small screen -> Wide screen (unfolding/rotating)
            if let lastRoute = path.last {
                switch lastRoute {
                case .settings:
                    detailPane = .settings
                case .parkingHistory:
                    detailPane = .parkingHistory
                case .map(let spotId, let onlyShow):
                    detailPane = .map
                    mapFocusSpotId = spotId
                    mapOnlyShowSpotId = onlyShow ? spotId : nil
                case .saveSpot:
                    detailPane = .map
                }
                path.removeAll()
            } else {
                detailPane = .map
            }
        } else {
            // Wide screen -> Small screen (folding/narrowing)
            switch detailPane {
            case .settings:
                if path.last != .settings {
                    path = [.settings]
                }
            case .parkingHistory:
                if path.last != .parkingHistory {
                    path = [.parkingHistory]
                }
            case .map:
                if isMapExpanded {
                    isMapExpanded = false
                    path = [.map(spotId: mapFocusSpotId, onlyShow: mapOnlyShowSpotId != nil)]
                }
            }
        }
    }

    func handleURL(_ url: URL) {
        let action = DeepLink.parse(url)
        switch action {
        case .park:
            parkHere()
        case .foundCar:
            DispatchQueue.main.async { [weak self] in
                self?.foundCar()
            }
        case .settings:
            openSettings()
        case .history:
            openParkingHistory()
        case .showMap(let id):
            openMap(spotId: id ?? StorageKeys.carId, onlyShow: true)
        case .showSpot(let id):
            openMap(spotId: id, onlyShow: true)
        case .openLocation(let parsed):
            openSaveSpot(lat: parsed?.latitude, lng: parsed?.longitude, name: parsed?.label)
        case .none:
            break
        }
    }

    private func sort(_ list: [Spot]) -> [Spot] {
        switch sortOrder {
        case .dateDesc:
            return list.sorted { $0.savedAt > $1.savedAt }
        case .name:
            return list.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .category:
            return list.sorted {
                if $0.category.rawValue == $1.category.rawValue {
                    return $0.name.lowercased() < $1.name.lowercased()
                }
                return $0.category.rawValue < $1.category.rawValue
            }
        case .nearest:
            guard let user = location.coordinate else { return list.sorted { $0.savedAt > $1.savedAt } }
            return list.sorted {
                DistanceFormatter.calculateDistance(from: user, to: $0.coordinate)
                    < DistanceFormatter.calculateDistance(from: user, to: $1.coordinate)
            }
        }
    }

    private func newId() -> String {
        String(Int(Date().timeIntervalSince1970 * 1_000_000), radix: 36)
    }
}

enum DeepLink {
    case park
    case foundCar
    case settings
    case history
    case showMap(String?)
    case showSpot(String)
    case openLocation(ParsedGeoLocation?)
    case none

    static func parse(_ url: URL) -> DeepLink {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "geo" {
            return .openLocation(GeoUriParser.parse(url.absoluteString))
        }
        let host = url.host?.lowercased() ?? url.path.split(separator: "/").first.map(String.init)?.lowercased() ?? ""
        let path = url.path
        switch host {
        case "park": return .park
        case "found_car", "found", "done": return .foundCar
        case "settings": return .settings
        case "history", "parking_history": return .history
        case "map", "car", "on_map":
            let spot = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "spot" })?.value
            return .showMap(spot ?? StorageKeys.carId)
        case "spot":
            let id = path.split(separator: "/").last.map(String.init) ?? ""
            return id.isEmpty ? .showMap(StorageKeys.carId) : .showSpot(id)
        case "save", "add":
            return .openLocation(GeoUriParser.parse(url.absoluteString))
        default:
            if let parsed = GeoUriParser.parse(url.absoluteString) {
                return .openLocation(parsed)
            }
            return .none
        }
    }
}
