import 'package:geolocator/geolocator.dart';

import '../models/location_access.dart';

class LocationService {
  const LocationService();

  Future<LocationAccess> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccess.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  Future<LocationAccess> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccess.serviceDisabled;
    }

    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  Future<Position?> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 6),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      final access = await checkPermission();
      if (access != LocationAccess.granted) return null;

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: accuracy,
            timeLimit: timeLimit,
          ),
        );
      } catch (_) {
        // Fallback to medium accuracy if high accuracy times out
        try {
          return await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (_) {
          return await getLastKnownPosition();
        }
      }
    } catch (_) {
      return await getLastKnownPosition();
    }
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  Stream<Position> getPositionStream({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  LocationAccess _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccess.granted;
      case LocationPermission.denied:
        return LocationAccess.denied;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationAccess.denied;
    }
  }
}
