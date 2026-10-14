import 'package:maplibre_gl/maplibre_gl.dart';

import '../constants/spot_categories.dart';
import '../constants/storage_keys.dart';

/// Status of a spot (specifically used for parking lifecycle: parking vs found).
enum SpotStatus {
  parking,
  found,
  none;

  static SpotStatus fromName(String? name) {
    if (name == null || name.isEmpty) return SpotStatus.none;
    for (final val in SpotStatus.values) {
      if (val.name == name) return val;
    }
    return SpotStatus.none;
  }
}

/// A saved place. Distance is computed at runtime and never stored.
class Spot {
  const Spot({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.savedAt,
    this.status = SpotStatus.none,
    this.parkedDuration,
  });

  final String id;
  final String name;
  final SpotCategory category;
  final double latitude;
  final double longitude;
  final DateTime savedAt;
  final SpotStatus status;
  final Duration? parkedDuration;

  bool get isCar => id == StorageKeys.carId || category == SpotCategory.car;
  bool get isParking =>
      status == SpotStatus.parking ||
      (id == StorageKeys.carId && status != SpotStatus.found);
  bool get isFound => status == SpotStatus.found;

  LatLng get latLng => LatLng(latitude, longitude);

  Duration get calculatedParkedDuration {
    if (parkedDuration != null) return parkedDuration!;
    final parts = id.split('_');
    if (parts.length >= 4) {
      final start = int.tryParse(parts[2]);
      final end = int.tryParse(parts[3]);
      if (start != null && end != null && end >= start) {
        return Duration(milliseconds: end - start);
      }
    }
    return DateTime.now().difference(savedAt);
  }

  Spot copyWith({
    String? id,
    String? name,
    SpotCategory? category,
    double? latitude,
    double? longitude,
    DateTime? savedAt,
    SpotStatus? status,
    Duration? parkedDuration,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      savedAt: savedAt ?? this.savedAt,
      status: status ?? this.status,
      parkedDuration: parkedDuration ?? this.parkedDuration,
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
          other.savedAt == savedAt &&
          other.status == status &&
          other.parkedDuration == parkedDuration;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        category,
        latitude,
        longitude,
        savedAt,
        status,
        parkedDuration,
      );
}
