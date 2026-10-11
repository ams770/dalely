import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/models/location_access.dart';
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
    SpotsMapMode initialMode = SpotsMapMode.viewing,
  })  : nameController = TextEditingController(),
        super(
          _computeInitialState(
            spotsCubit: spotsCubit,
            locationCubit: locationCubit,
            initialSelectedSpotId: initialSelectedSpotId,
            initialMode: initialMode,
          ),
        ) {
    _init();
  }

  final SpotsCubit spotsCubit;
  final LocationCubit locationCubit;
  final MarkerIconCache markerIconCache;
  final AppThemeExtension themeExtension;
  final String? initialSelectedSpotId;
  final TextEditingController nameController;

  GoogleMapController? _mapController;
  StreamSubscription? _spotsSubscription;
  StreamSubscription? _locationSubscription;

  static SpotsMapState _computeInitialState({
    required SpotsCubit spotsCubit,
    required LocationCubit locationCubit,
    String? initialSelectedSpotId,
    SpotsMapMode initialMode = SpotsMapMode.viewing,
  }) {
    Spot? selectedSpot;
    if (initialSelectedSpotId != null && initialMode == SpotsMapMode.viewing) {
      for (final s in spotsCubit.state.allSpots) {
        if (s.id == initialSelectedSpotId) {
          selectedSpot = s;
          break;
        }
      }
    }

    LatLng target = const LatLng(30.0444, 31.2357);
    if (initialMode == SpotsMapMode.addSpot) {
      if (locationCubit.state.hasLocation) {
        target = locationCubit.state.latLng!;
      } else if (spotsCubit.state.car != null) {
        target = spotsCubit.state.car!.latLng;
      }
    } else {
      if (selectedSpot != null) {
        target = selectedSpot.latLng;
      } else if (spotsCubit.state.car != null) {
        target = spotsCubit.state.car!.latLng;
      } else if (spotsCubit.state.spots.isNotEmpty) {
        target = spotsCubit.state.spots.first.latLng;
      } else if (locationCubit.state.hasLocation) {
        target = locationCubit.state.latLng!;
      }
    }

    return SpotsMapState(
      mode: initialMode,
      selectedSpot: selectedSpot,
      initialTarget: target,
      initialZoom: 16.5,
      currentZoom: 16.5,
      pickedLocation: target,
      category: SpotCategory.market,
    );
  }

  void _init() {
    nameController.addListener(() {
      final text = nameController.text;
      if (text != state.spotName && !isClosed) {
        emit(state.copyWith(spotName: text));
      }
    });

    _rebuildMarkers();

    _spotsSubscription = spotsCubit.stream.listen((_) {
      if (!isClosed) _rebuildMarkers();
    });

    _locationSubscription = locationCubit.stream.listen((_) {
      if (!isClosed) _rebuildMarkers();
    });
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (state.isAddingSpot) {
      final userPos = locationCubit.state.latLng;
      if (userPos != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(userPos, 16.5),
        );
      }
    } else if (initialSelectedSpotId != null) {
      selectSpotById(initialSelectedSpotId!);
    } else {
      _fitAllSpotsOrUser();
    }
  }

  void onCameraMoveStarted() {
    if (!state.isCameraMoving && !isClosed) {
      emit(state.copyWith(isCameraMoving: true));
    }
  }

  void onCameraMove(CameraPosition position) {
    final newTier = MarkerZoomTier.fromZoom(position.zoom);
    final tierChanged = newTier != state.zoomTier;

    if (state.isAddingSpot) {
      emit(state.copyWith(
        currentZoom: position.zoom,
        pickedLocation: position.target,
      ));
    } else if (tierChanged) {
      emit(state.copyWith(currentZoom: position.zoom));
    }

    if (tierChanged) {
      _rebuildMarkers();
    }
  }

  Future<void> onCameraIdle() async {
    if (_mapController == null) return;
    try {
      final zoom = await _mapController!.getZoomLevel();
      final newTier = MarkerZoomTier.fromZoom(zoom);
      final tierChanged = newTier != state.zoomTier;

      if (!isClosed) {
        emit(state.copyWith(
          isCameraMoving: false,
          currentZoom: zoom,
        ));
      }

      if (tierChanged) {
        _rebuildMarkers();
      }
    } catch (_) {}
  }

  void enterAddSpotMode({LatLng? initialTarget}) {
    final target = initialTarget ??
        locationCubit.state.latLng ??
        state.pickedLocation;
    nameController.clear();
    emit(state.copyWith(
      mode: SpotsMapMode.addSpot,
      clearSelected: true,
      pickedLocation: target,
      spotName: '',
      category: SpotCategory.market,
      isSaving: false,
      isCameraMoving: false,
    ));
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(target, 16.5),
    );
  }

  void exitAddSpotMode() {
    nameController.clear();
    emit(state.copyWith(
      mode: SpotsMapMode.viewing,
      spotName: '',
      isSaving: false,
      isCameraMoving: false,
    ));
    _rebuildMarkers();
  }

  void setCategory(SpotCategory category) {
    emit(state.copyWith(category: category));
  }

  Future<void> snapToCurrentLocation() async {
    var pos = locationCubit.state.latLng;
    if (pos == null) {
      final access = await locationCubit.requestPermission();
      if (access != LocationAccess.granted) return;
      pos = locationCubit.state.latLng;
    }

    if (pos != null) {
      emit(state.copyWith(pickedLocation: pos));
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(pos, 16.5),
      );
    }
  }

  Future<Spot?> saveCurrentSpot() async {
    if (!state.canSave) return null;

    emit(state.copyWith(isSaving: true));
    try {
      final spot = await spotsCubit.saveSpot(
        name: state.spotName.trim(),
        category: state.category,
        latitude: state.pickedLocation.latitude,
        longitude: state.pickedLocation.longitude,
      );

      if (!isClosed) {
        nameController.clear();
        emit(state.copyWith(
          mode: SpotsMapMode.viewing,
          isSaving: false,
          selectedSpot: spot,
        ));
        _rebuildMarkers();
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(spot.latLng, 16.5),
        );
      }
      return spot;
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
      return null;
    }
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
      final BitmapDescriptor icon;
      if (spot.isCar) {
        icon = await markerIconCache.getCarMarker(
          isSelected: isSelected,
          tier: tier,
        );
      } else {
        final color = themeExtension.categoryColor(spot.category);
        icon = await markerIconCache.getCategoryMarker(
          category: spot.category,
          color: color,
          isSelected: isSelected,
          tier: tier,
        );
      }

      markers.add(
        Marker(
          markerId: MarkerId('spot_${spot.id}'),
          position: spot.latLng,
          icon: icon,
          anchor: tier.anchor,
          zIndexInt: isSelected ? 10 : (spot.isCar ? 8 : 2),
          onTap: state.isAddingSpot ? null : () => selectSpot(spot),
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
    if (state.isAddingSpot) return;

    if (spot == null) {
      emit(state.copyWith(clearSelected: true));
    } else {
      emit(state.copyWith(selectedSpot: spot));
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(spot.latLng, 16.5),
      );
    }
    _rebuildMarkers();
  }

  void selectSpotById(String id) {
    if (state.isAddingSpot) {
      exitAddSpotMode();
    }
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
        CameraUpdate.newLatLngZoom(userPos, 16.5),
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
        CameraUpdate.newLatLngZoom(spots.first.latLng, 16.5),
      );
      return;
    }

    final points = <LatLng>[
      ?userPos,
      for (final spot in spots) spot.latLng,
    ];

    if (points.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 16.5),
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
    nameController.dispose();
    _mapController?.dispose();
    return super.close();
  }
}
