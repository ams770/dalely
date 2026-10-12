import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/marker_icon_cache.dart';

enum SpotsMapMode { viewing, addSpot }

class SpotsMapState {
  const SpotsMapState({
    this.mode = SpotsMapMode.viewing,
    this.selectedSpot,
    this.markers = const <Marker>{},
    this.initialTarget = const LatLng(30.0444, 31.2357),
    this.initialZoom = 20.0,
    this.currentZoom = 20.0,
    this.pickedLocation = const LatLng(30.0444, 31.2357),
    this.spotName = '',
    this.category = SpotCategory.other,
    this.isCameraMoving = false,
    this.isSaving = false,
    this.isMapReady = false,
  });

  final bool isMapReady;

  final SpotsMapMode mode;
  final Spot? selectedSpot;
  final Set<Marker> markers;
  final LatLng initialTarget;
  final double initialZoom;
  final double currentZoom;
  final LatLng pickedLocation;
  final String spotName;
  final SpotCategory category;
  final bool isCameraMoving;
  final bool isSaving;

  bool get isAddingSpot => mode == SpotsMapMode.addSpot;
  bool get canSave => spotName.trim().isNotEmpty && !isSaving;
  MarkerZoomTier get zoomTier => MarkerZoomTier.fromZoom(currentZoom);

  SpotsMapState copyWith({
    SpotsMapMode? mode,
    Spot? selectedSpot,
    bool clearSelected = false,
    Set<Marker>? markers,
    LatLng? initialTarget,
    double? initialZoom,
    double? currentZoom,
    LatLng? pickedLocation,
    String? spotName,
    SpotCategory? category,
    bool? isCameraMoving,
    bool? isSaving,
    bool? isMapReady,
  }) {
    return SpotsMapState(
      mode: mode ?? this.mode,
      selectedSpot: clearSelected ? null : (selectedSpot ?? this.selectedSpot),
      markers: markers ?? this.markers,
      initialTarget: initialTarget ?? this.initialTarget,
      initialZoom: initialZoom ?? this.initialZoom,
      currentZoom: currentZoom ?? this.currentZoom,
      pickedLocation: pickedLocation ?? this.pickedLocation,
      spotName: spotName ?? this.spotName,
      category: category ?? this.category,
      isCameraMoving: isCameraMoving ?? this.isCameraMoving,
      isSaving: isSaving ?? this.isSaving,
      isMapReady: isMapReady ?? this.isMapReady,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotsMapState &&
          other.mode == mode &&
          other.selectedSpot == selectedSpot &&
          other.initialTarget == initialTarget &&
          other.initialZoom == initialZoom &&
          other.currentZoom == currentZoom &&
          other.pickedLocation == pickedLocation &&
          other.spotName == spotName &&
          other.category == category &&
          other.isCameraMoving == isCameraMoving &&
          other.isSaving == isSaving &&
          other.isMapReady == isMapReady &&
          _setEquals(other.markers, markers);

  @override
  int get hashCode => Object.hash(
    mode,
    selectedSpot,
    initialTarget,
    initialZoom,
    currentZoom,
    pickedLocation,
    spotName,
    category,
    isCameraMoving,
    isSaving,
    isMapReady,
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
