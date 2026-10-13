import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/location_access.dart';

class LocationState {
  const LocationState({
    this.access = LocationAccess.denied,
    this.position,
    this.heading = 0.0,
    this.isLoading = false,
  });

  final LocationAccess access;
  final Position? position;
  final double heading;
  final bool isLoading;

  bool get hasLocation => position != null;
  bool get isGranted => access == LocationAccess.granted;

  LatLng? get latLng =>
      position != null ? LatLng(position!.latitude, position!.longitude) : null;

  LocationState copyWith({
    LocationAccess? access,
    Position? position,
    double? heading,
    bool? isLoading,
  }) {
    return LocationState(
      access: access ?? this.access,
      position: position ?? this.position,
      heading: heading ?? this.heading,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationState &&
          other.access == access &&
          other.position?.latitude == position?.latitude &&
          other.position?.longitude == position?.longitude &&
          other.heading == heading &&
          other.isLoading == isLoading;

  @override
  int get hashCode =>
      Object.hash(access, position?.latitude, position?.longitude, heading, isLoading);
}
