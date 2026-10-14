import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/marker_icon_cache.dart';

enum SpotsMapMode { viewing, addSpot }

class SpotsMapState {
  const SpotsMapState({
    this.mode = SpotsMapMode.viewing,
    this.selectedSpot,
    this.initialTarget = const LatLng(30.0444, 31.2357),
    this.initialZoom = 17.0,
    this.currentZoom = 17.0,
    this.pickedLocation = const LatLng(30.0444, 31.2357),
    this.spotName = '',
    this.category = SpotCategory.other,
    this.isCameraMoving = false,
    this.isSaving = false,
    this.isMapReady = false,
    this.editingSpot,
  });

  final bool isMapReady;
  final SpotsMapMode mode;
  final Spot? selectedSpot;
  final Spot? editingSpot;
  final LatLng initialTarget;
  final double initialZoom;
  final double currentZoom;
  final LatLng pickedLocation;
  final String spotName;
  final SpotCategory category;
  final bool isCameraMoving;
  final bool isSaving;

  bool get isAddingSpot => mode == SpotsMapMode.addSpot;
  bool get isEditingSpot => editingSpot != null;
  bool get canSave => spotName.trim().isNotEmpty && !isSaving;
  MarkerZoomTier get zoomTier => MarkerZoomTier.fromZoom(currentZoom);

  SpotsMapState copyWith({
    SpotsMapMode? mode,
    Spot? selectedSpot,
    bool clearSelected = false,
    Spot? editingSpot,
    bool clearEditingSpot = false,
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
      editingSpot:
          clearEditingSpot ? null : (editingSpot ?? this.editingSpot),
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
          other.editingSpot == editingSpot &&
          other.initialTarget == initialTarget &&
          other.initialZoom == initialZoom &&
          other.currentZoom == currentZoom &&
          other.pickedLocation == pickedLocation &&
          other.spotName == spotName &&
          other.category == category &&
          other.isCameraMoving == isCameraMoving &&
          other.isSaving == isSaving &&
          other.isMapReady == isMapReady;

  @override
  int get hashCode => Object.hash(
    mode,
    selectedSpot,
    editingSpot,
    initialTarget,
    initialZoom,
    currentZoom,
    pickedLocation,
    spotName,
    category,
    isCameraMoving,
    isSaving,
    isMapReady,
  );
}
