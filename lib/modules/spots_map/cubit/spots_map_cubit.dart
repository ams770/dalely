import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/models/location_access.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/marker_icon_cache.dart';
import '../../../shared/theme/app_theme_extension.dart';
import 'spots_map_state.dart';

class SpotsMapCubit extends Cubit<SpotsMapState> {
  static const double defaultZoom = 17.0;

  SpotsMapCubit({
    required this.spotsCubit,
    required this.locationCubit,
    required this.markerIconCache,
    required this.themeExtension,
    bool isDarkMode = false,
    this.initialSelectedSpotId,
    this.initialTarget,
    String? initialSpotName,
    SpotsMapMode initialMode = SpotsMapMode.viewing,
  }) : _isDarkMode = isDarkMode,
       nameController = TextEditingController(text: initialSpotName ?? ''),
       super(
         _computeInitialState(
           spotsCubit: spotsCubit,
           locationCubit: locationCubit,
           isDarkMode: isDarkMode,
           initialSelectedSpotId: initialSelectedSpotId,
           initialTarget: initialTarget,
           initialSpotName: initialSpotName,
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
  final LatLng? initialTarget;
  final TextEditingController nameController;

  final bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  MapLibreMapController? _mapController;
  StreamSubscription? _spotsSubscription;
  StreamSubscription? _locationSubscription;
  bool _hasCenteredOnUser = false;
  bool _styleLoaded = false;

  static SpotsMapState _computeInitialState({
    required SpotsCubit spotsCubit,
    required LocationCubit locationCubit,
    bool isDarkMode = false,
    String? initialSelectedSpotId,
    LatLng? initialTarget,
    String? initialSpotName,
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
      if (initialTarget != null) {
        target = initialTarget;
      } else if (locationCubit.state.hasLocation) {
        target = locationCubit.state.latLng!;
      } else if (spotsCubit.state.car != null) {
        target = spotsCubit.state.car!.latLng;
      }
    } else {
      if (selectedSpot != null) {
        target = selectedSpot.latLng;
      } else if (locationCubit.state.hasLocation) {
        target = locationCubit.state.latLng!;
      } else if (spotsCubit.state.car != null) {
        target = spotsCubit.state.car!.latLng;
      } else if (spotsCubit.state.spots.isNotEmpty) {
        target = spotsCubit.state.spots.first.latLng;
      }
    }

    return SpotsMapState(
      mode: initialMode,
      selectedSpot: selectedSpot,
      initialTarget: target,
      pickedLocation: target,
      spotName: initialSpotName ?? '',
      category: SpotCategory.other,
      isMapReady: !isDarkMode,
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

    _locationSubscription = locationCubit.stream.listen((locState) {
      if (!isClosed) {
        _rebuildMarkers();
        if (state.selectedSpot == null &&
            !state.isAddingSpot &&
            !_hasCenteredOnUser &&
            locState.hasLocation &&
            _mapController != null) {
          _hasCenteredOnUser = true;
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(locState.latLng!, defaultZoom),
          );
        }
      }
    });
  }

  void onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _mapController?.onSymbolTapped.add(_handleSymbolTapped);
  }

  Future<void> onStyleLoaded() async {
    _styleLoaded = true;
    if (!isClosed) {
      emit(state.copyWith(isMapReady: true));
    }
    await _registerMarkerImages();
    await _rebuildMarkers();

    if (state.isAddingSpot) {
      final target = initialTarget ?? locationCubit.state.latLng;
      if (target != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, defaultZoom),
        );
      }
    } else if (initialSelectedSpotId != null) {
      selectSpotById(initialSelectedSpotId!);
    } else {
      final userPos = locationCubit.state.latLng;
      if (userPos != null) {
        _hasCenteredOnUser = true;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(userPos, defaultZoom),
        );
      }
    }
  }

  void _handleSymbolTapped(Symbol symbol) {
    final spotId = symbol.data?['spotId'] as String?;
    if (spotId != null && !state.isAddingSpot) {
      selectSpotById(spotId);
    }
  }

  void onCameraMoveStarted() {
    if (!state.isCameraMoving && !isClosed) {
      emit(state.copyWith(isCameraMoving: true));
    }
  }

  void onCameraMove(CameraPosition position) {
    if (state.isAddingSpot) {
      emit(
        state.copyWith(
          isCameraMoving: true,
          currentZoom: position.zoom,
          pickedLocation: position.target,
        ),
      );
    }
  }

  void onCameraIdle() {
    if (!isClosed && state.isCameraMoving) {
      emit(state.copyWith(isCameraMoving: false));
    }
  }

  void enterAddSpotMode({LatLng? initialTarget}) {
    final target =
        initialTarget ?? locationCubit.state.latLng ?? state.pickedLocation;
    nameController.clear();
    emit(
      state.copyWith(
        mode: SpotsMapMode.addSpot,
        clearSelected: true,
        pickedLocation: target,
        spotName: '',
        category: SpotCategory.other,
        isSaving: false,
        isCameraMoving: false,
      ),
    );
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(target, defaultZoom),
    );
  }

  void exitAddSpotMode() {
    nameController.clear();
    emit(
      state.copyWith(
        mode: SpotsMapMode.viewing,
        spotName: '',
        isSaving: false,
        isCameraMoving: false,
      ),
    );
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
        CameraUpdate.newLatLngZoom(pos, defaultZoom),
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
        emit(
          state.copyWith(
            mode: SpotsMapMode.viewing,
            isSaving: false,
            selectedSpot: spot,
          ),
        );
        _rebuildMarkers();
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(spot.latLng, defaultZoom),
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

  Future<void> _registerMarkerImages() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      // 1. Car marker
      final carBytes = await markerIconCache.getCarMarker(isSelected: false);
      await controller.addImage('car_pin', carBytes);

      final carSelectedBytes = await markerIconCache.getCarMarker(isSelected: true);
      await controller.addImage('car_pin_selected', carSelectedBytes);

      // 2. Categories
      for (final cat in SpotCategory.values) {
        if (cat == SpotCategory.car) continue;
        final color = themeExtension.categoryColor(cat);
        final unselected = await markerIconCache.getCategoryMarker(
          category: cat,
          color: color,
          isSelected: false,
        );
        await controller.addImage('category_${cat.name}', unselected);

        final selected = await markerIconCache.getCategoryMarker(
          category: cat,
          color: color,
          isSelected: true,
        );
        await controller.addImage('category_${cat.name}_selected', selected);
      }

      // 3. User location
      final userBytes = await markerIconCache.getUserLocationMarker(heading: 0.0);
      await controller.addImage('user_location', userBytes);
    } catch (_) {
      // Ignore if engine is tearing down
    }
  }

  Future<void> _rebuildMarkers() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;

    final spots = spotsCubit.state.allSpots;
    final locState = locationCubit.state;
    final selected = state.selectedSpot;

    try {
      await controller.clearSymbols();

      // 1. Spot markers
      for (final spot in spots) {
        final isSelected = selected?.id == spot.id;
        final imageName = spot.isCar
            ? (isSelected ? 'car_pin_selected' : 'car_pin')
            : (isSelected ? 'category_${spot.category.name}_selected' : 'category_${spot.category.name}');

        await controller.addSymbol(
          SymbolOptions(
            geometry: spot.latLng,
            iconImage: imageName,
            iconSize: isSelected ? 0.65 : 0.52,
            iconAnchor: 'bottom',
            zIndex: isSelected ? 10 : (spot.isCar ? 8 : 2),
          ),
          {'spotId': spot.id},
        );
      }

      // 2. User location custom marker
      if (locState.hasLocation) {
        final userPos = locState.latLng!;
        await controller.addSymbol(
          SymbolOptions(
            geometry: userPos,
            iconImage: 'user_location',
            iconSize: 0.48,
            iconAnchor: 'center',
            iconRotate: locState.heading,
            zIndex: 5,
          ),
          {'type': 'user_location'},
        );
      }
    } catch (_) {
      // Style might be reloading during theme changes
    }
  }

  void selectSpot(Spot? spot) {
    if (state.isAddingSpot) return;

    if (spot == null) {
      emit(state.copyWith(clearSelected: true));
    } else {
      emit(state.copyWith(selectedSpot: spot));
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(spot.latLng, defaultZoom),
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
      _hasCenteredOnUser = true;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userPos, defaultZoom),
      );
    } else {
      _hasCenteredOnUser = false;
      locationCubit.requestPermission();
    }
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    _locationSubscription?.cancel();
    nameController.dispose();
    _mapController?.onSymbolTapped.remove(_handleSymbolTapped);
    _mapController?.dispose();
    return super.close();
  }
}

