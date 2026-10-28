import '../l10n/generated/app_localizations.dart';
import '../models/spot.dart';

abstract final class SpotLinkBuilder {
  /// Builds a Google Maps URL for the given coordinates.
  static String mapUrl({required double latitude, required double longitude}) {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  /// Builds share text for a single spot: `"Name - https://maps.google.com/?q=lat,lng"`.
  static String buildSingle(Spot spot, {required AppLocalizations l10n}) {
    final displayName = spot.isCar
        ? (spot.name.trim().isEmpty ? l10n.myCar : spot.name)
        : spot.name;
    final url = mapUrl(latitude: spot.latitude, longitude: spot.longitude);
    return '$displayName - $url';
  }

  /// Builds combined share text for a list of spots.
  /// If the car is present, it is put first.
  static String buildAll(List<Spot> spots, {required AppLocalizations l10n}) {
    if (spots.isEmpty) return '';

    final ordered = List<Spot>.from(spots)
      ..sort((a, b) {
        if (a.isCar) return -1;
        if (b.isCar) return 1;
        return b.savedAt.compareTo(a.savedAt);
      });

    return ordered
        .map((spot) => buildSingle(spot, l10n: l10n))
        .join('\n\n');
  }
}
