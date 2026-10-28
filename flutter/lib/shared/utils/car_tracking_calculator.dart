import 'dart:math' as math;

/// Pure-Dart calculator for car walking distance, walk time, progress, and arrival state.
class CarTrackingCalculator {
  const CarTrackingCalculator._();

  static const double walkingSpeedMetersPerSecond = 1.4;
  static const double arrivalDistanceMeters = 15.0;
  static const double arrivalMaxAccuracyMeters = 25.0;
  static const double departureDistanceMeters = 30.0;
  static const double maxTrackingDistanceMeters = 50000.0; // 50 km

  /// Calculates the geodesic distance between two points on Earth using the Haversine formula.
  static double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degreesToRadians(endLatitude - startLatitude);
    final dLon = _degreesToRadians(endLongitude - startLongitude);

    final lat1 = _degreesToRadians(startLatitude);
    final lat2 = _degreesToRadians(endLatitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);

  /// Formats distance according to the spec:
  /// - Under 100 m: rounded to nearest 5 m (e.g. 15 m)
  /// - 100 to 999 m: rounded to nearest 10 m (e.g. 240 m)
  /// - 1 km or more: one decimal place (e.g. 1.2 km)
  static String formatDistance(double meters, {bool isArabic = false}) {
    final clampedMeters = meters < 0 ? 0.0 : meters;

    if (clampedMeters < 100.0) {
      final rounded = ((clampedMeters / 5.0).round() * 5).toInt();
      final unit = isArabic ? 'م' : 'm';
      return '$rounded $unit';
    } else if (clampedMeters < 1000.0) {
      final rounded = ((clampedMeters / 10.0).round() * 10).toInt();
      if (rounded >= 1000) {
        final km = (rounded / 1000.0).toStringAsFixed(1);
        final unit = isArabic ? 'كم' : 'km';
        return '$km $unit';
      }
      final unit = isArabic ? 'م' : 'm';
      return '$rounded $unit';
    } else {
      final km = (clampedMeters / 1000.0).toStringAsFixed(1);
      final unit = isArabic ? 'كم' : 'km';
      return '$km $unit';
    }
  }

  /// Calculates walk time in minutes:
  /// distance / 1.4 m/s, rounded up to whole minutes.
  /// If under 1 minute (less than 60 seconds), returns 0.
  static int calculateWalkMinutes(double meters) {
    if (meters <= 0) return 0;
    final seconds = meters / walkingSpeedMetersPerSecond;
    if (seconds < 60.0 - 1e-6) {
      return 0;
    }
    // Epsilon avoids 60.00000000000001 from ceiling to 2
    return ((seconds - 1e-6) / 60.0).ceil();
  }

  /// Formats walk time:
  /// Under 1 minute: "Less than a minute"
  /// 1 minute or more: "About N min walk"
  static String formatWalkTime(int minutes, {bool isArabic = false}) {
    if (minutes <= 0) {
      return isArabic ? 'أقل من دقيقة' : 'Less than a minute';
    }

    if (isArabic) {
      if (minutes == 1) {
        return 'حوالي دقيقة سيرًا';
      } else if (minutes == 2) {
        return 'حوالي دقيقتين سيرًا';
      } else if (minutes >= 3 && minutes <= 10) {
        return 'حوالي $minutes دقائق سيرًا';
      } else {
        return 'حوالي $minutes دقيقة سيرًا';
      }
    } else {
      if (minutes == 1) {
        return 'About 1 min walk';
      }
      return 'About $minutes min walk';
    }
  }

  /// Calculates progress as a clamped double between 0.0 and 1.0.
  /// progress = clamp(1 - distance / startDistance, 0, 1).
  static double calculateProgress({
    required double currentDistance,
    required double startDistance,
  }) {
    if (startDistance <= 0.0) return 1.0;
    final raw = 1.0 - (currentDistance / startDistance);
    if (raw < 0.0) return 0.0;
    if (raw > 1.0) return 1.0;
    return raw;
  }

  /// Determines if startDistance should be reset because user moved beyond 1.5x startDistance.
  static bool shouldResetStartDistance({
    required double currentDistance,
    required double startDistance,
  }) {
    return currentDistance > (1.5 * startDistance);
  }

  /// Checks arrival state using hysteresis:
  /// - Enters arrived when distance <= 15 m and horizontal accuracy <= 25 m.
  /// - Leaves arrived only when distance > 30 m.
  static bool checkArrival({
    required double distance,
    required double horizontalAccuracy,
    required bool currentlyArrived,
  }) {
    if (currentlyArrived) {
      return distance <= departureDistanceMeters;
    } else {
      return distance <= arrivalDistanceMeters &&
          horizontalAccuracy <= arrivalMaxAccuracyMeters;
    }
  }

  /// Returns true if car distance exceeds 50 km (cannot start walking tracking).
  static bool isTooFar(double distanceMeters) {
    return distanceMeters > maxTrackingDistanceMeters;
  }
}
