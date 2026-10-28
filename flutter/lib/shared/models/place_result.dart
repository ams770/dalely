import 'package:maplibre_gl/maplibre_gl.dart';

/// A place returned by the place search.
class PlaceResult {
  const PlaceResult({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;

  LatLng get latLng => LatLng(latitude, longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceResult &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => Object.hash(title, subtitle, latitude, longitude);
}
