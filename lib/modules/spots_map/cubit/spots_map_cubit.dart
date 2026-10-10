import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/marker_icon_cache.dart';
import '../../../shared/theme/app_theme_extension.dart';
import 'spots_map_state.dart';

class SpotsMapCubit extends Cubit<SpotsMapState> {
  SpotsMapCubit({
    required this.spotsCubit,
    required this.locationCubit,
    required this.markerIconCache,
    required this.themeExtension,
    this.initialSelectedSpotId,
  }) : super(const SpotsMapState()) {
    _init();
  }

  final SpotsCubit spotsCubit;
  final LocationCubit locationCubit;
  final MarkerIconCache markerIconCache;
  final AppThemeExtension themeExtension;
  final String? initialSelectedSpotId;

  GoogleMapController? _mapController;
  StreamSubscription? _spotsSubscription;
  StreamSubscription? _locationSubscription;

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (initialSelectedSpotId != null) {
      selectSpotById(initialSelectedSpotId!);
    } else {
      _fitAllSpotsOrUser();
    }
  }

  void _init() {
    _rebuildMarkers();

    _spotsSubscription = spotsCubit.stream.listen((_) {
      if (!isClosed) _rebuildMarkers();
    });

    _locationSubscription = locationCubit.stream.listen((_) {
      if (!isClosed) _rebuildMarkers();
    });
  }

  void onCameraMove(CameraPosition position) {
    final newTier = MarkerZoomTier.fromZoom(position.zoom);
    if (newTier != state.zoomTier) {
      emit(state.copyWith(currentZoom: position.zoom));
      _rebuildMarkers();
    }
  }

  Future<void> onCameraIdle() async {
    if (_mapController == null) return;
    try {
      final zoom = await _mapController!.getZoomLevel();
      final newTier = MarkerZoomTier.fromZoom(zoom);
      if (newTier != state.zoomTier) {
        emit(state.copyWith(currentZoom: zoom));
        _rebuildMarkers();
      }
    } catch (_) {}
  }

  Future<void> _rebuildMarkers() async {
    final spots = spotsCubit.state.allSpots;
    final locState = locationCubit.state;
    final selected = state.selectedSpot;
    final tier = state.zoomTier;

    final markers = <Marker>{};

    // 1. Spot markers
    for (final spot in spots) {
      final isSelected = selected?.id == spot.id;
      final color = themeExtension.categoryColor(spot.category);
      final icon = await markerIconCache.getCategoryMarker(
        category: spot.category,
        color: color,
        isSelected: isSelected,
        tier: tier,
      );

      markers.add(
        Marker(
          markerId: MarkerId('spot_${spot.id}'),
          position: spot.latLng,
          icon: icon,
          anchor: tier.anchor,
          zIndexInt: isSelected ? 10 : 2,
          onTap: () => selectSpot(spot),
        ),
      );
    }

    // 2. User location custom marker (with direction cone)
    if (locState.hasLocation) {
      final userPos = locState.latLng!;
      final userIcon = await markerIconCache.getUserLocationMarker(
        heading: locState.heading,
      );

      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userPos,
          icon: userIcon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndexInt: 5,
        ),
      );
    }

    if (!isClosed) {
      emit(state.copyWith(markers: markers));
    }
  }

  void selectSpot(Spot? spot) {
    if (spot == null) {
      emit(state.copyWith(clearSelected: true));
    } else {
      emit(state.copyWith(selectedSpot: spot));
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(spot.latLng, 16.0),
      );
    }
    _rebuildMarkers();
  }

  void selectSpotById(String id) {
    final all = spotsCubit.state.allSpots;
    for (final spot in all) {
      if (spot.id == id) {
        selectSpot(spot);
        return;
      }
    }
  }

  void recenterOnUser() {
    final userPos = locationCubit.state.latLng;
    if (userPos != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userPos, 16.0),
      );
    } else {
      locationCubit.requestPermission();
    }
  }

  void _fitAllSpotsOrUser() {
    final spots = spotsCubit.state.allSpots;
    final userPos = locationCubit.state.latLng;

    if (spots.isEmpty && userPos == null) return;

    if (spots.length == 1 && userPos == null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(spots.first.latLng, 15.0),
      );
      return;
    }

    final points = <LatLng>[
      ?userPos,
      for (final spot in spots) spot.latLng,
    ];

    if (points.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15.0),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80.0,
      ),
    );
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    return super.close();
  }
}
