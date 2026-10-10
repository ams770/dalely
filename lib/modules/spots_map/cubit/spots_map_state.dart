import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/models/spot.dart';
import '../../../shared/services/marker_icon_cache.dart';

class SpotsMapState {
  const SpotsMapState({
    this.selectedSpot,
    this.markers = const <Marker>{},
    this.initialTarget = const LatLng(30.0444, 31.2357),
    this.initialZoom = 14.0,
    this.currentZoom = 14.0,
  });

  final Spot? selectedSpot;
  final Set<Marker> markers;
  final LatLng initialTarget;
  final double initialZoom;
  final double currentZoom;

  MarkerZoomTier get zoomTier => MarkerZoomTier.fromZoom(currentZoom);

  SpotsMapState copyWith({
    Spot? selectedSpot,
    bool clearSelected = false,
    Set<Marker>? markers,
    LatLng? initialTarget,
    double? initialZoom,
    double? currentZoom,
  }) {
    return SpotsMapState(
      selectedSpot: clearSelected ? null : (selectedSpot ?? this.selectedSpot),
      markers: markers ?? this.markers,
      initialTarget: initialTarget ?? this.initialTarget,
      initialZoom: initialZoom ?? this.initialZoom,
      currentZoom: currentZoom ?? this.currentZoom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotsMapState &&
          other.selectedSpot == selectedSpot &&
          other.initialTarget == initialTarget &&
          other.initialZoom == initialZoom &&
          other.currentZoom == currentZoom &&
          _setEquals(other.markers, markers);

  @override
  int get hashCode => Object.hash(
        selectedSpot,
        initialTarget,
        initialZoom,
        currentZoom,
        Object.hashAll(markers),
      );

  static bool _setEquals(Set<Marker> a, Set<Marker> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }
}
