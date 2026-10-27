import Combine
import CoreLocation
import UIKit

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var isStarted = false

    var access: LocationAccess = .unknown
    var coordinate: CLLocationCoordinate2D?
    var heading: CLLocationDirection = 0
    var accuracy: CLLocationAccuracy = 0
    var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = true
    }

    var hasLocation: Bool { coordinate != nil }

    func requestPermission() {
        switch access {
        case .unknown:
            manager.requestWhenInUseAuthorization()
        case .denied, .deniedForever, .serviceDisabled:
            openSettings()
        case .granted:
            start()
        }
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func start() {
        isStarted = true
        if access == .granted {
            startUpdating()
        }
    }

    func stop() {
        isStarted = false
        stopUpdating()
    }

    private func startUpdating() {
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    private func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            access = .granted
            if isStarted {
                startUpdating()
            }
        case .denied, .restricted:
            stopUpdating()
            DispatchQueue.global(qos: .utility).async {
                let enabled = CLLocationManager.locationServicesEnabled()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.access = enabled ? .deniedForever : .serviceDisabled
                }
            }
        case .notDetermined:
            access = .unknown
        @unknown default:
            access = .unknown
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        coordinate = location.coordinate
        accuracy = location.horizontalAccuracy
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        if abs(value - heading) > 3 {
            heading = value
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            stopUpdating()
            DispatchQueue.global(qos: .utility).async {
                let enabled = CLLocationManager.locationServicesEnabled()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.access = enabled ? .deniedForever : .serviceDisabled
                }
            }
        }
    }
}
