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
import '../../../shared/theme/map_styles.dart';
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
  final String? initialSelectedSpotId;
  final LatLng? initialTarget;
  final TextEditingController nameController;

  AppThemeExtension themeExtension;

  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  void updateTheme({
    required bool isDarkMode,
    required AppThemeExtension themeExtension,
  }) {
    if (_isDarkMode == isDarkMode && this.themeExtension == themeExtension) {
      return;
    }
    _isDarkMode = isDarkMode;
    this.themeExtension = themeExtension;

    final style = isDarkMode ? MapStyles.dark : MapStyles.light;
    final controller = _mapController;
    if (controller != null && !controller.isDisposed) {
      controller.setStyle(style);
      _registerMarkerImages().then((_) {
        if (!isClosed) _rebuildMarkers();
      });
    }
  }

  MapLibreMapController? _mapController;
  StreamSubscription? _spotsSubscription;
  StreamSubscription? _locationSubscription;
  bool _hasCenteredOnUser = false;
  bool _styleLoaded = false;
  bool _isRebuildingMarkers = false;
  bool _needsRebuildMarkers = false;

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
        final controller = _mapController;
        if (state.selectedSpot == null &&
            !state.isAddingSpot &&
            !_hasCenteredOnUser &&
            locState.hasLocation &&
            controller != null &&
            !controller.isDisposed) {
          _hasCenteredOnUser = true;
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(locState.latLng!, defaultZoom),
          );
        }
      }
    });
  }

  void onMapCreated(MapLibreMapController controller) {
    if (_mapController != null && !_mapController!.isDisposed) {
      _mapController!.onSymbolTapped.remove(_handleSymbolTapped);
    }
    _mapController = controller;
    if (!controller.isDisposed) {
      controller.onSymbolTapped.add(_handleSymbolTapped);
    }
  }

  Future<void> onStyleLoaded() async {
    _styleLoaded = true;
    if (!isClosed) {
      emit(state.copyWith(isMapReady: true));
    }
    final controller = _mapController;
    if (controller == null || controller.isDisposed || isClosed) return;

    await controller.setSymbolIconAllowOverlap(true);
    if (controller.isDisposed || isClosed) return;
    await controller.setSymbolIconIgnorePlacement(true);
    if (controller.isDisposed || isClosed) return;
    await _registerMarkerImages();
    if (controller.isDisposed || isClosed) return;
    await _rebuildMarkers();
    if (controller.isDisposed || isClosed) return;

    if (state.isAddingSpot) {
      final target = initialTarget ?? locationCubit.state.latLng;
      if (target != null && !controller.isDisposed) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(target, defaultZoom),
        );
      }
    } else if (initialSelectedSpotId != null) {
      selectSpotById(initialSelectedSpotId!);
    } else {
      final userPos = locationCubit.state.latLng;
      if (userPos != null && !controller.isDisposed) {
        _hasCenteredOnUser = true;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(userPos, defaultZoom),
        );
      }
    }
  }

  void _handleSymbolTapped(Symbol symbol) {
    if (isClosed) return;
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
    final controller = _mapController;
    if (controller != null && !controller.isDisposed) {
      final targetZoom =
          state.currentZoom > defaultZoom ? state.currentZoom : defaultZoom;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(target, targetZoom),
      );
    }
  }

  void onMapLongClick(LatLng coords) {
    enterAddSpotMode(initialTarget: coords);
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
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(pos, defaultZoom),
        );
      }
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
    if (controller == null || controller.isDisposed || isClosed) return;

    try {
      // 1. Car marker
      final carBytes = await markerIconCache.getCarMarker(isSelected: false);
      if (controller.isDisposed || isClosed) return;
      await controller.addImage('car_pin', carBytes);

      final carSelectedBytes = await markerIconCache.getCarMarker(isSelected: true);
      if (controller.isDisposed || isClosed) return;
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
        if (controller.isDisposed || isClosed) return;
        await controller.addImage('category_${cat.name}', unselected);

        final selected = await markerIconCache.getCategoryMarker(
          category: cat,
          color: color,
          isSelected: true,
        );
        if (controller.isDisposed || isClosed) return;
        await controller.addImage('category_${cat.name}_selected', selected);
      }

      // 3. User location
      final userBytes = await markerIconCache.getUserLocationMarker(heading: 0.0);
      if (controller.isDisposed || isClosed) return;
      await controller.addImage('user_location', userBytes);
    } catch (_) {
      // Ignore if engine is tearing down
    }
  }

  Future<void> _rebuildMarkers() async {
    final controller = _mapController;
    if (controller == null || controller.isDisposed || !_styleLoaded || isClosed) return;

    if (_isRebuildingMarkers) {
      _needsRebuildMarkers = true;
      return;
    }

    _isRebuildingMarkers = true;
    _needsRebuildMarkers = false;

    try {
      if (controller.isDisposed || isClosed) return;
      await controller.setSymbolIconAllowOverlap(true);
      if (controller.isDisposed || isClosed) return;
      await controller.setSymbolIconIgnorePlacement(true);

      final spots = spotsCubit.state.allSpots;
      final locState = locationCubit.state;
      final selected = state.selectedSpot;

      final options = <SymbolOptions>[];
      final data = <Map<String, dynamic>>[];

      // 1. User location marker (lowest zIndex so spots always sit on top and receive taps)
      if (locState.hasLocation) {
        options.add(
          SymbolOptions(
            geometry: locState.latLng!,
            iconImage: 'user_location',
            iconSize: 0.60,
            iconAnchor: 'center',
            iconRotate: locState.heading,
            zIndex: 1,
          ),
        );
        data.add({'type': 'user_location'});
      }

      // 2. Spot markers (zIndex higher than user location; selected spot sits topmost)
      for (final spot in spots) {
        final isSelected = selected?.id == spot.id;
        final imageName = spot.isCar
            ? (isSelected ? 'car_pin_selected' : 'car_pin')
            : (isSelected
                ? 'category_${spot.category.name}_selected'
                : 'category_${spot.category.name}');

        options.add(
          SymbolOptions(
            geometry: spot.latLng,
            iconImage: imageName,
            iconSize: isSelected ? 1.05 : 0.85,
            iconAnchor: 'bottom',
            zIndex: isSelected ? 10 : (spot.isCar ? 8 : 4),
          ),
        );
        data.add({'spotId': spot.id});
      }

      if (controller.isDisposed || isClosed) return;
      await controller.clearSymbols();
      if (controller.isDisposed || isClosed) return;
      await controller.addSymbols(options, data);
    } catch (_) {
      // Style might be reloading during theme changes
    } finally {
      _isRebuildingMarkers = false;
      if (_needsRebuildMarkers && !isClosed) {
        _rebuildMarkers();
      }
    }
  }

  void selectSpot(Spot? spot) {
    if (state.isAddingSpot) return;

    if (spot == null) {
      emit(state.copyWith(clearSelected: true));
    } else {
      emit(state.copyWith(selectedSpot: spot));
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(spot.latLng, defaultZoom),
        );
      }
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
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(userPos, defaultZoom),
        );
      }
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
    final controller = _mapController;
    if (controller != null && !controller.isDisposed) {
      controller.onSymbolTapped.remove(_handleSymbolTapped);
    }
    _mapController = null;
    return super.close();
  }
}

