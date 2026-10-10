import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

import '../models/place_result.dart';

class PlaceSearchService {
  PlaceSearchService({this.geocoding}) : _geocoding = geocoding ?? Geocoding();

  final Geocoding? geocoding;
  final Geocoding _geocoding;

  Future<List<PlaceResult>> search(String query, {Locale? locale}) async {
    final clean = query.trim();
    if (clean.isEmpty) return const [];

    try {
      final locations = await _geocoding.locationFromAddress(
        clean,
        locale: locale,
      );

      final results = <PlaceResult>[];
      for (final loc in locations.take(5)) {
        String title = clean;
        String subtitle = '';

        try {
          final placemarks = await _geocoding.placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
            locale: locale,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            title = [
              if (p.name != null && p.name!.isNotEmpty) p.name,
              if (p.street != null && p.street != p.name) p.street,
            ].join(', ');
            if (title.isEmpty) title = clean;

            subtitle = [
              if (p.subLocality != null) p.subLocality,
              if (p.locality != null) p.locality,
              if (p.administrativeArea != null) p.administrativeArea,
              if (p.country != null) p.country,
            ].where((s) => s != null && s.isNotEmpty).join(', ');
          }
        } catch (_) {
          // If reverse geocode fails, use coordinates as subtitle
          subtitle = '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
        }

        results.add(
          PlaceResult(
            title: title,
            subtitle: subtitle,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
      }

      return results;
    } catch (_) {
      return const [];
    }
  }
}
