import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
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
    this.editingSpot,
    SpotsMapMode initialMode = SpotsMapMode.viewing,
    this.onlyShowSpotId,
  }) : _isDarkMode = isDarkMode,
       nameController = TextEditingController(
         text: editingSpot?.name ?? initialSpotName ?? '',
       ),
       super(
         _computeInitialState(
           spotsCubit: spotsCubit,
           locationCubit: locationCubit,
           isDarkMode: isDarkMode,
           initialSelectedSpotId: initialSelectedSpotId,
           onlyShowSpotId: onlyShowSpotId,
           initialTarget: editingSpot?.latLng ?? initialTarget,
           initialSpotName: editingSpot?.name ?? initialSpotName,
           editingSpot: editingSpot,
           initialMode: editingSpot != null
               ? SpotsMapMode.addSpot
               : initialMode,
         ),
       ) {
    _currentCameraTarget = state.initialTarget;
    if (initialMode == SpotsMapMode.addSpot ||
        editingSpot != null ||
        initialTarget != null ||
        initialSelectedSpotId != null ||
        onlyShowSpotId != null) {
      _hasCenteredOnUser = true;
    }
    _init();
  }

  final SpotsCubit spotsCubit;
  final LocationCubit locationCubit;
  final MarkerIconCache markerIconCache;
  final String? initialSelectedSpotId;
  final String? onlyShowSpotId;
  final LatLng? initialTarget;
  final Spot? editingSpot;
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
  LatLng? _currentCameraTarget;
  double _currentBearing = 0.0;
  Symbol? _userLocationSymbol;
  double _topPadding = 0;
  double _bottomPadding = 0;
  double _screenWidth = 0;
  double _screenHeight = 0;
  double _devicePixelRatio = 1.0;

  void updatePinScreenMetrics({
    required double topPadding,
    required double bottomPadding,
    required double screenWidth,
    required double screenHeight,
    double devicePixelRatio = 1.0,
  }) {
    _topPadding = topPadding;
    _bottomPadding = bottomPadding;
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;
    _devicePixelRatio = devicePixelRatio;
  }

  Point<double> get pinScreenPoint {
    final x = _screenWidth > 0 ? _screenWidth / 2 : 200.0;
    final y = _screenHeight > 0
        ? _topPadding + (_screenHeight - _topPadding - _bottomPadding) / 2
        : 300.0;
    return Point<double>(x, y);
  }

  Point<double> get screenCenterPoint {
    final x = _screenWidth > 0 ? _screenWidth / 2 : 200.0;
    final y = _screenHeight > 0 ? _screenHeight / 2 : 400.0;
    return Point<double>(x, y);
  }

  double get pinCenterOffsetDy {
    return screenCenterPoint.y - pinScreenPoint.y;
  }

  LatLng? get currentCameraTarget => _currentCameraTarget;

  Point<double> _toPlatformScreenPoint(Point<double> logicalPoint) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final ratio = _devicePixelRatio > 0 ? _devicePixelRatio : 1.0;
      return Point<double>(logicalPoint.x * ratio, logicalPoint.y * ratio);
    }
    return logicalPoint;
  }

  Point<double> _fromPlatformScreenPoint(Point<num> platformPoint) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final ratio = _devicePixelRatio > 0 ? _devicePixelRatio : 1.0;
      return Point<double>(platformPoint.x / ratio, platformPoint.y / ratio);
    }
    return Point<double>(
      platformPoint.x.toDouble(),
      platformPoint.y.toDouble(),
    );
  }

  static SpotsMapState _computeInitialState({
    required SpotsCubit spotsCubit,
    required LocationCubit locationCubit,
    bool isDarkMode = false,
    String? initialSelectedSpotId,
    String? onlyShowSpotId,
    LatLng? initialTarget,
    String? initialSpotName,
    Spot? editingSpot,
    SpotsMapMode initialMode = SpotsMapMode.viewing,
  }) {
    Spot? selectedSpot;
    final targetSpotId = initialSelectedSpotId ?? onlyShowSpotId;
    if (targetSpotId != null && initialMode == SpotsMapMode.viewing) {
      final all = spotsCubit.state.allSpots.followedBy(
        spotsCubit.state.parkingHistory,
      );
      for (final s in all) {
        if (s.id == targetSpotId) {
          selectedSpot = s;
          break;
        }
      }
    }

    LatLng target = const LatLng(30.0444, 31.2357);
    if (editingSpot != null) {
      target = editingSpot.latLng;
    } else if (initialMode == SpotsMapMode.addSpot) {
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
      mode: editingSpot != null ? SpotsMapMode.addSpot : initialMode,
      selectedSpot: selectedSpot,
      onlyShowSpotId: onlyShowSpotId,
      editingSpot: editingSpot,
      initialTarget: target,
      pickedLocation: target,
      spotName: editingSpot?.name ?? initialSpotName ?? '',
      category: editingSpot?.category ?? SpotCategory.other,
      isMapReady: !isDarkMode,
      openedToAdd: editingSpot != null || initialMode == SpotsMapMode.addSpot,
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
        final controller = _mapController;
        final sym = _userLocationSymbol;

        if (sym != null &&
            locState.hasLocation &&
            controller != null &&
            !controller.isDisposed) {
          final bearing = _currentBearing;
          final iconRotate = ((locState.heading - bearing) % 360 + 360) % 360;
          controller.updateSymbol(
            sym,
            SymbolOptions(geometry: locState.latLng!, iconRotate: iconRotate),
          );
        } else {
          _rebuildMarkers();
        }

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

    final targetSpotId =
        initialSelectedSpotId ?? onlyShowSpotId ?? state.onlyShowSpotId;
    if (state.isAddingSpot) {
      _hasCenteredOnUser = true;
      final target = initialTarget ?? locationCubit.state.latLng;
      if (target != null && !controller.isDisposed) {
        await _animateTargetToPin(target, zoom: defaultZoom);
      }
    } else if (targetSpotId != null) {
      _hasCenteredOnUser = true;
      final shouldOnlyShow =
          onlyShowSpotId != null || state.onlyShowSpotId != null;
      selectSpotById(targetSpotId, onlyShowSpot: shouldOnlyShow);
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
      selectSpotById(spotId, onlyShowSpot: state.onlyShowSpotId != null);
    }
  }

  void onCameraMoveStarted() {
    _hasCenteredOnUser = true;
    if (!state.isCameraMoving && !isClosed) {
      emit(state.copyWith(isCameraMoving: true));
    }
  }

  void onCameraMove(CameraPosition position) {
    _currentCameraTarget = position.target;
    final oldBearing = _currentBearing;
    _currentBearing = position.bearing;
    _hasCenteredOnUser = true;

    // Update user location symbol rotation dynamically to cancel map bearing
    final sym = _userLocationSymbol;
    final locState = locationCubit.state;
    final controller = _mapController;
    if (sym != null &&
        locState.hasLocation &&
        controller != null &&
        !controller.isDisposed) {
      if ((position.bearing - oldBearing).abs() >= 0.5) {
        final iconRotate =
            ((locState.heading - position.bearing) % 360 + 360) % 360;
        controller.updateSymbol(sym, SymbolOptions(iconRotate: iconRotate));
      }
    }

    if (state.isAddingSpot) {
      if (position.zoom != state.currentZoom || !state.isCameraMoving) {
        emit(state.copyWith(isCameraMoving: true, currentZoom: position.zoom));
      }
    } else {
      if (position.zoom != state.currentZoom) {
        emit(state.copyWith(currentZoom: position.zoom));
      }
    }
  }

  Future<void> onCameraIdle() async {
    if (!isClosed && state.isCameraMoving) {
      emit(state.copyWith(isCameraMoving: false));
    }
    final controller = _mapController;
    if (controller != null && !controller.isDisposed) {
      final bearing = controller.cameraPosition?.bearing ?? _currentBearing;
      _currentBearing = bearing;
      final sym = _userLocationSymbol;
      final locState = locationCubit.state;
      if (sym != null && locState.hasLocation) {
        final iconRotate = ((locState.heading - bearing) % 360 + 360) % 360;
        controller.updateSymbol(sym, SymbolOptions(iconRotate: iconRotate));
      }

      if (state.isAddingSpot) {
        try {
          final loc = await controller.toLatLng(
            _toPlatformScreenPoint(pinScreenPoint),
          );
          if (!isClosed && state.isAddingSpot) {
            emit(state.copyWith(pickedLocation: loc));
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _animateTargetToPin(
    LatLng target, {
    Point<double>? screenPoint,
    double? zoom,
  }) async {
    final controller = _mapController;
    if (controller == null || controller.isDisposed || isClosed) return;
    try {
      Point<double> touchLogicalPoint;
      if (screenPoint != null) {
        touchLogicalPoint = _fromPlatformScreenPoint(screenPoint);
      } else {
        final raw = await controller.toScreenLocation(target);
        touchLogicalPoint = _fromPlatformScreenPoint(raw);
      }
      final targetLogicalPoint = Point<double>(
        touchLogicalPoint.x,
        touchLogicalPoint.y + pinCenterOffsetDy,
      );
      final targetCameraCenter = await controller.toLatLng(
        _toPlatformScreenPoint(targetLogicalPoint),
      );
      if (!controller.isDisposed && !isClosed) {
        final update = zoom != null
            ? CameraUpdate.newLatLngZoom(targetCameraCenter, zoom)
            : CameraUpdate.newLatLng(targetCameraCenter);
        await controller.animateCamera(update);
      }
    } catch (_) {
      if (!controller.isDisposed && !isClosed) {
        final update = zoom != null
            ? CameraUpdate.newLatLngZoom(target, zoom)
            : CameraUpdate.newLatLng(target);
        await controller.animateCamera(update);
      }
    }
  }

  void enterAddSpotMode({
    LatLng? initialTarget,
    Point<double>? touchScreenPoint,
  }) {
    _hasCenteredOnUser = true;
    final target =
        initialTarget ??
        _currentCameraTarget ??
        _mapController?.cameraPosition?.target ??
        state.pickedLocation;
    nameController.clear();
    emit(
      state.copyWith(
        mode: SpotsMapMode.addSpot,
        clearSelected: true,
        clearEditingSpot: true,
        pickedLocation: target,
        spotName: '',
        category: SpotCategory.other,
        isSaving: false,
        isCameraMoving: false,
        openedToAdd: false,
      ),
    );

    // If an explicit target was provided (e.g. from onMapLongClick),
    // smoothly scroll it to the pin center.
    // If initialTarget was null (e.g. clicking the "Add spot" button),
    // DO NOT animate camera: keep current camera position and query pin coordinates.
    if (initialTarget != null) {
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        _animateTargetToPin(initialTarget, screenPoint: touchScreenPoint);
      }
    } else {
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        controller
            .toLatLng(_toPlatformScreenPoint(pinScreenPoint))
            .then((loc) {
              if (!isClosed && state.isAddingSpot) {
                emit(state.copyWith(pickedLocation: loc));
              }
            })
            .catchError((_) {});
      }
    }
  }

  void enterEditSpotMode(Spot spot) {
    _hasCenteredOnUser = true;
    nameController.text = spot.name;
    emit(
      state.copyWith(
        mode: SpotsMapMode.addSpot,
        clearSelected: true,
        editingSpot: spot,
        pickedLocation: spot.latLng,
        spotName: spot.name,
        category: spot.category,
        isSaving: false,
        isCameraMoving: false,
        openedToAdd: false,
      ),
    );
    final controller = _mapController;
    if (controller != null && !controller.isDisposed) {
      _animateTargetToPin(spot.latLng, zoom: defaultZoom);
    }
  }

  void onMapLongClick(LatLng coords, {Point<double>? screenPoint}) {
    _hasCenteredOnUser = true;
    enterAddSpotMode(initialTarget: coords, touchScreenPoint: screenPoint);
  }

  void exitAddSpotMode() {
    nameController.clear();
    _hasCenteredOnUser = true;
    emit(
      state.copyWith(
        mode: SpotsMapMode.viewing,
        clearEditingSpot: true,
        spotName: '',
        isSaving: false,
        isCameraMoving: false,
        openedToAdd: false,
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
        await _animateTargetToPin(pos, zoom: defaultZoom);
      }
    }
  }

  Future<Spot?> saveCurrentSpot() async {
    if (!state.canSave) return null;

    final controller = _mapController;
    LatLng saveLocation = state.pickedLocation;
    if (controller != null && !controller.isDisposed) {
      try {
        saveLocation = await controller.toLatLng(
          _toPlatformScreenPoint(pinScreenPoint),
        );
      } catch (_) {}
    }

    emit(state.copyWith(isSaving: true, pickedLocation: saveLocation));
    try {
      final Spot spot;
      if (state.editingSpot != null) {
        spot = state.editingSpot!.copyWith(
          name: state.spotName.trim(),
          category: state.category,
          latitude: saveLocation.latitude,
          longitude: saveLocation.longitude,
        );
        await spotsCubit.updateSpot(spot);
      } else {
        spot = await spotsCubit.saveSpot(
          name: state.spotName.trim(),
          category: state.category,
          latitude: saveLocation.latitude,
          longitude: saveLocation.longitude,
        );
      }

      if (!isClosed) {
        nameController.clear();
        emit(
          state.copyWith(
            mode: SpotsMapMode.viewing,
            isSaving: false,
            selectedSpot: spot,
            clearEditingSpot: true,
            openedToAdd: false,
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

      final carSelectedBytes = await markerIconCache.getCarMarker(
        isSelected: true,
      );
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
      final userBytes = await markerIconCache.getUserLocationMarker(
        heading: 0.0,
      );
      if (controller.isDisposed || isClosed) return;
      await controller.addImage('user_location', userBytes);
    } catch (_) {
      // Ignore if engine is tearing down
    }
  }

  Future<void> _rebuildMarkers() async {
    final controller = _mapController;
    if (controller == null ||
        controller.isDisposed ||
        !_styleLoaded ||
        isClosed)
      return;

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

      final locState = locationCubit.state;
      final selected = state.selectedSpot;

      final options = <SymbolOptions>[];
      final data = <Map<String, dynamic>>[];

      // 1. User location marker (lowest zIndex so spots always sit on top and receive taps)
      // Icon rotation is compensated by map bearing so cone points in physical device heading
      if (locState.hasLocation) {
        final bearing = _currentBearing;
        final iconRotate = ((locState.heading - bearing) % 360 + 360) % 360;
        options.add(
          SymbolOptions(
            geometry: locState.latLng!,
            iconImage: 'user_location',
            iconSize: 0.60,
            iconAnchor: 'center',
            iconRotate: iconRotate,
            zIndex: 1,
          ),
        );
        data.add({'type': 'user_location'});
      }

      // Determine which spots to render (show only isolated spot if onlyShowSpotId is active)
      final Iterable<Spot> spotsToRender;
      if (state.onlyShowSpotId != null) {
        if (selected != null && selected.id == state.onlyShowSpotId) {
          spotsToRender = [selected];
        } else {
          final found = spotsCubit.state.allSpots
              .followedBy(spotsCubit.state.parkingHistory)
              .where((s) => s.id == state.onlyShowSpotId);
          spotsToRender = found.isNotEmpty ? [found.first] : const [];
        }
      } else {
        final all = spotsCubit.state.allSpots.toList();
        if (selected != null && !all.any((s) => s.id == selected.id)) {
          all.add(selected);
        }
        spotsToRender = all;
      }

      // 2. Spot markers (zIndex higher than user location; selected spot sits topmost)
      // iconAnchor: 'bottom' places the marker tip directly on the exact coordinates
      for (final spot in spotsToRender) {
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
      final addedSymbols = await controller.addSymbols(options, data);
      _userLocationSymbol = null;
      for (var i = 0; i < data.length; i++) {
        if (data[i]['type'] == 'user_location' && i < addedSymbols.length) {
          _userLocationSymbol = addedSymbols[i];
          break;
        }
      }
    } catch (_) {
      // Style might be reloading during theme changes
    } finally {
      _isRebuildingMarkers = false;
      if (_needsRebuildMarkers && !isClosed) {
        _rebuildMarkers();
      }
    }
  }

  void selectSpot(Spot? spot, {bool onlyShowSpot = false}) {
    if (state.isAddingSpot) return;

    if (spot == null) {
      emit(state.copyWith(clearSelected: true, clearOnlyShowSpot: true));
    } else {
      emit(
        state.copyWith(
          selectedSpot: spot,
          onlyShowSpotId: onlyShowSpot ? spot.id : null,
          clearOnlyShowSpot: !onlyShowSpot,
        ),
      );
      final controller = _mapController;
      if (controller != null && !controller.isDisposed) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(spot.latLng, defaultZoom),
        );
      }
    }
    _rebuildMarkers();
  }

  void selectSpotById(String id, {bool onlyShowSpot = false}) {
    if (state.isAddingSpot) {
      exitAddSpotMode();
    }
    final all = spotsCubit.state.allSpots.followedBy(
      spotsCubit.state.parkingHistory,
    );
    for (final spot in all) {
      if (spot.id == id) {
        selectSpot(spot, onlyShowSpot: onlyShowSpot);
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
