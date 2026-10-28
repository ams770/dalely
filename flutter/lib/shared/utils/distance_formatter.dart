import 'package:geolocator/geolocator.dart';

import '../l10n/generated/app_localizations.dart';

abstract final class DistanceFormatter {
  /// Computes distance in meters between two coordinates.
  static double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Formats distance in meters into localized text (e.g. "450 m" or "1.2 km").
  static String format(double meters, AppLocalizations l10n) {
    if (meters < 1000) {
      final rounded = meters.round();
      return l10n.distanceMeters(rounded.toString());
    }
    final kilometers = meters / 1000.0;
    final value = kilometers < 10
        ? kilometers.toStringAsFixed(1)
        : kilometers.round().toString();
    return l10n.distanceKilometers(value);
  }

  /// Compact distance format for notifications and widgets (e.g. "450 m" or "1.2 km").
  static String formatShort(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final kilometers = meters / 1000.0;
    final value = kilometers < 10
        ? kilometers.toStringAsFixed(1)
        : kilometers.round().toString();
    return '$value km';
  }
}
