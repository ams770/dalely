import 'package:maplibre_gl/maplibre_gl.dart';

import '../constants/spot_categories.dart';
import '../constants/storage_keys.dart';

/// A saved place. Distance is computed at runtime and never stored.
class Spot {
  const Spot({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.savedAt,
  });

  final String id;
  final String name;
  final SpotCategory category;
  final double latitude;
  final double longitude;
  final DateTime savedAt;

  bool get isCar => id == StorageKeys.carId;

  LatLng get latLng => LatLng(latitude, longitude);

  Spot copyWith({
    String? name,
    SpotCategory? category,
    double? latitude,
    double? longitude,
    DateTime? savedAt,
  }) {
    return Spot(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Spot &&
          other.id == id &&
          other.name == name &&
          other.category == category &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.savedAt == savedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, category, latitude, longitude, savedAt);
}
