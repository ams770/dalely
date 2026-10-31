import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
  static const double defaultZoom = 17.0;

  /// Opacity of the other spots while the user is picking a point.
  static const double _inactiveMarkerOpacity = 0.45;

  // Marker scales (same values the old MapLibre `iconSize` used).
  static const double _spotScale = 0.85;
  static const double _selectedSpotScale = 1.05;
  static const double _userScale = 0.60;

  static const String _userMarkerId = 'user_location';

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

  /// Markers to draw. Google Maps is declarative, so the screen listens to this
  /// and passes the set to `AppMap(markers: ...)`.
  final ValueNotifier<Set<Marker>> markersNotifier =
      ValueNotifier<Set<Marker>>(const <Marker>{});

  AppThemeExtension themeExtension;

  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  /// The map style itself follows the theme through `AppMap` (its `style`
  /// parameter), so here we only need to re-render the themed marker icons.
  void updateTheme({
    required bool isDarkMode,
    required AppThemeExtension themeExtension,
  }) {
    if (_isDarkMode == isDarkMode && this.themeExtension == themeExtension) {
      return;
    }
    _isDarkMode = isDarkMode;
    this.themeExtension = themeExtension;

    if (_mapController != null) {
      _loadMarkerIcons().then((_) {
        if (!isClosed) _rebuildMarkers();
      });
    }
  }

  GoogleMapController? _mapController;
  StreamSubscription? _spotsSubscription;
  StreamSubscription? _locationSubscription;
  bool _hasCenteredOnUser = false;
  bool _mapReady = false;
  LatLng? _currentCameraTarget;
  double _topPadding = 0;
  double _bottomPadding = 0;
  double _screenWidth = 0;
  double _screenHeight = 0;
  double _devicePixelRatio = 1.0;

  final Map<String, BitmapDescriptor> _icons = {};
  Set<Marker> _spotMarkers = const <Marker>{};
  Marker? _userMarker;

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

  // ---------------------------------------------------------------------
  // Screen <-> LatLng helpers.
  // NOTE: depending on your google_maps_flutter version, Android's
  // getScreenCoordinate/getLatLng use physical pixels (older versions) or
  // logical pixels (newer ones). The DPR scaling below matches the old
  // behaviour; if the pin location is off by a factor of the device pixel
  // ratio on Android, remove the Android branch in these two helpers.
  // ---------------------------------------------------------------------

  ScreenCoordinate _toPlatformScreenCoordinate(Point<double> logicalPoint) {
    var x = logicalPoint.x;
    var y = logicalPoint.y;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final ratio = _devicePixelRatio > 0 ? _devicePixelRatio : 1.0;
      x *= ratio;
      y *= ratio;
    }
    return ScreenCoordinate(x: x.round(), y: y.round());
  }

  Point<double> _fromPlatformScreenCoordinate(ScreenCoordinate coordinate) {
    var x = coordinate.x.toDouble();
    var y = coordinate.y.toDouble();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final ratio = _devicePixelRatio > 0 ? _devicePixelRatio : 1.0;
      x /= ratio;
      y /= ratio;
    }
    return Point<double>(x, y);
  }

  /// Coordinate currently under the center pin, or null when unavailable.
  Future<LatLng?> _latLngUnderPin() async {
    final controller = _mapController;
    if (controller == null) return null;
    try {
      return await controller.getLatLng(
        _toPlatformScreenCoordinate(pinScreenPoint),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _animate(CameraUpdate update) async {
    final controller = _mapController;
    if (controller == null || isClosed) return;
    try {
      await controller.animateCamera(update);
    } catch (_) {
      // Map view may have been disposed.
    }
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

    _spotsSubscription = spotsCubit.stream.listen((_) {
      if (!isClosed) _rebuildMarkers();
    });

    _locationSubscription = locationCubit.stream.listen((locState) {
      if (isClosed) return;

      // Only the user marker depends on the location; flat markers rotate with
      // the map, so no bearing compensation is needed.
      _rebuildUserMarker();

      if (state.selectedSpot == null &&
          !state.isAddingSpot &&
          !_hasCenteredOnUser &&
          locState.hasLocation &&
          _mapController != null) {
        _hasCenteredOnUser = true;
        _animate(CameraUpdate.newLatLngZoom(locState.latLng!, defaultZoom));
      }
    });
  }

  /// Replaces the old `onMapCreated` + `onStyleLoaded` pair: Google Maps has
  /// no separate style-loaded callback, so everything runs once the map exists.
  Future<void> onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    _mapReady = true;
    _scheduleMapReveal();

    await _loadMarkerIcons();
    if (isClosed || _mapController != controller) return;
    _rebuildMarkers();

    final targetSpotId =
        initialSelectedSpotId ?? onlyShowSpotId ?? state.onlyShowSpotId;
    if (state.isAddingSpot) {
      _hasCenteredOnUser = true;
      final target = initialTarget ?? locationCubit.state.latLng;
      if (target != null) {
        await _animateTargetToPin(target, zoom: defaultZoom);
      }
    } else if (targetSpotId != null) {
      _hasCenteredOnUser = true;
      final shouldOnlyShow =
          onlyShowSpotId != null || state.onlyShowSpotId != null;
      selectSpotById(targetSpotId, onlyShowSpot: shouldOnlyShow);
    } else {
      final userPos = locationCubit.state.latLng;
      if (userPos != null) {
        _hasCenteredOnUser = true;
        _animate(CameraUpdate.newLatLngZoom(userPos, defaultZoom));
      }
    }
  }

  /// Other spots are inactive while the user is adding a spot.
  void _handleSpotTapped(String spotId) {
    if (isClosed || state.isAddingSpot) return;
    selectSpotById(spotId, onlyShowSpot: state.onlyShowSpotId != null);
  }

  void onCameraMoveStarted() {
    _hasCenteredOnUser = true;
    if (!state.isCameraMoving && !isClosed) {
      emit(state.copyWith(isCameraMoving: true));
    }
  }

  void onCameraMove(CameraPosition position) {
    _currentCameraTarget = position.target;
    _hasCenteredOnUser = true;

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

  Timer? _revealTimer;
  bool _revealed = false;

  /// In dark mode the loading mask hides the native map until its style has
  /// been applied, so the user never sees the default light map first.
  /// Light mode starts with `isMapReady == true`, so nothing is delayed there.
  void _scheduleMapReveal() {
    if (state.isMapReady) {
      _revealed = true;
      return;
    }
    // Fallback in case no camera-idle event ever arrives.
    _revealTimer?.cancel();
    _revealTimer = Timer(const Duration(milliseconds: 1500), _revealMap);
  }

  void _onFirstCameraIdle() {
    if (_revealed || !_mapReady) return;
    _revealTimer?.cancel();
    // Small grace period so the style and first tiles are on screen.
    _revealTimer = Timer(const Duration(milliseconds: 250), _revealMap);
  }

  void _revealMap() {
    if (_revealed || isClosed) return;
    _revealed = true;
    emit(state.copyWith(isMapReady: true));
  }

  Future<void> onCameraIdle() async {
    _onFirstCameraIdle();
    if (!isClosed && state.isCameraMoving) {
      emit(state.copyWith(isCameraMoving: false));
    }
    if (state.isAddingSpot) {
      final loc = await _latLngUnderPin();
      if (loc != null && !isClosed && state.isAddingSpot) {
        emit(state.copyWith(pickedLocation: loc));
      }
    }
  }

  Future<void> _animateTargetToPin(
    LatLng target, {
    Point<double>? screenPoint,
    double? zoom,
  }) async {
    final controller = _mapController;
    if (controller == null || isClosed) return;
    try {
      // `screenPoint`, when given, is already in logical pixels
      // (Google Maps' onLongPress doesn't provide one, so it is usually null).
      final Point<double> touchLogicalPoint;
      if (screenPoint != null) {
        touchLogicalPoint = screenPoint;
      } else {
        final raw = await controller.getScreenCoordinate(target);
        touchLogicalPoint = _fromPlatformScreenCoordinate(raw);
      }
      final targetLogicalPoint = Point<double>(
        touchLogicalPoint.x,
        touchLogicalPoint.y + pinCenterOffsetDy,
      );
      final targetCameraCenter = await controller.getLatLng(
        _toPlatformScreenCoordinate(targetLogicalPoint),
      );
      if (!isClosed) {
        await _animate(
          zoom != null
              ? CameraUpdate.newLatLngZoom(targetCameraCenter, zoom)
              : CameraUpdate.newLatLng(targetCameraCenter),
        );
      }
    } catch (_) {
      if (!isClosed) {
        await _animate(
          zoom != null
              ? CameraUpdate.newLatLngZoom(target, zoom)
              : CameraUpdate.newLatLng(target),
        );
      }
    }
  }

  void enterAddSpotMode({
    LatLng? initialTarget,
    Point<double>? touchScreenPoint,
  }) {
    _hasCenteredOnUser = true;
    final target =
        initialTarget ?? _currentCameraTarget ?? state.pickedLocation;
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
        isDetailsSheetOpen: false,
      ),
    );
    // Dim the other spots and make them inactive.
    _rebuildMarkers();

    // If an explicit target was provided (e.g. from onMapLongClick),
    // smoothly scroll it to the pin center.
    // If initialTarget was null (e.g. clicking the "Add spot" button),
    // DO NOT animate camera: keep current camera position and query pin coordinates.
    if (initialTarget != null) {
      if (_mapController != null) {
        _animateTargetToPin(initialTarget, screenPoint: touchScreenPoint);
      }
    } else {
      _latLngUnderPin().then((loc) {
        if (loc != null && !isClosed && state.isAddingSpot) {
          emit(state.copyWith(pickedLocation: loc));
        }
      });
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
        isDetailsSheetOpen: false,
      ),
    );
    // Hide the edited spot (the pin replaces it) and dim the others.
    _rebuildMarkers();
    if (_mapController != null) {
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
        isDetailsSheetOpen: false,
      ),
    );
    _rebuildMarkers();
  }

  /// Called when the user taps "Pick here".
  ///
  /// Resolves the exact coordinate under the pin, stores it in the state and marks the
  /// details sheet as open. Returns `false` when the sheet must not be opened
  /// (not in add mode, or it is already open), so a double tap can't open two sheets.
  Future<bool> pickCurrentPoint() async {
    if (isClosed || !state.isAddingSpot || state.isDetailsSheetOpen) {
      return false;
    }
    // Set the flag first so a second tap is ignored while the coordinate resolves.
    emit(state.copyWith(isDetailsSheetOpen: true));

    final location = await _latLngUnderPin() ?? state.pickedLocation;

    if (isClosed || !state.isAddingSpot) return false;
    emit(state.copyWith(pickedLocation: location));
    return true;
  }

  /// Called when the details sheet is dismissed (cancel button, swipe down or back).
  /// The user returns to picking: the pin and the "Pick here" button stay.
  void closeDetailsSheet() {
    if (isClosed || !state.isDetailsSheetOpen) return;
    emit(state.copyWith(isDetailsSheetOpen: false));
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
      if (_mapController != null) {
        await _animateTargetToPin(pos, zoom: defaultZoom);
      }
    }
  }

  Future<Spot?> saveCurrentSpot() async {
    if (!state.canSave) return null;

    final saveLocation = await _latLngUnderPin() ?? state.pickedLocation;

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
        // Leaving add mode also closes the details sheet (the screen listens for it).
        emit(
          state.copyWith(
            mode: SpotsMapMode.viewing,
            isSaving: false,
            selectedSpot: spot,
            clearEditingSpot: true,
            openedToAdd: false,
            isDetailsSheetOpen: false,
          ),
        );
        _rebuildMarkers();
        _animate(CameraUpdate.newLatLngZoom(spot.latLng, defaultZoom));
      }
      return spot;
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Markers
  // ---------------------------------------------------------------------

  /// Converts rendered PNG bytes to a [BitmapDescriptor].
  ///
  /// `imagePixelRatio` controls the on-screen size: logical size =
  /// image pixels / imagePixelRatio. The value below assumes the icon cache
  /// renders at the device pixel ratio; if markers look too big or small,
  /// tune this one line (e.g. use `1 / scale` instead).
  BitmapDescriptor _descriptor(Uint8List bytes, double scale) {
    final dpr = _devicePixelRatio > 0 ? _devicePixelRatio : 1.0;
    return BitmapDescriptor.bytes(bytes, imagePixelRatio: dpr / scale);
  }

  Future<void> _loadMarkerIcons() async {
    if (isClosed) return;
    try {
      final icons = <String, BitmapDescriptor>{};

      // 1. Car marker
      icons['car_pin'] = _descriptor(
        await markerIconCache.getCarMarker(isSelected: false),
        _spotScale,
      );
      icons['car_pin_selected'] = _descriptor(
        await markerIconCache.getCarMarker(isSelected: true),
        _selectedSpotScale,
      );

      // 2. Categories
      for (final cat in SpotCategory.values) {
        if (cat == SpotCategory.car) continue;
        final color = themeExtension.categoryColor(cat);
        icons['category_${cat.name}'] = _descriptor(
          await markerIconCache.getCategoryMarker(
            category: cat,
            color: color,
            isSelected: false,
          ),
          _spotScale,
        );
        icons['category_${cat.name}_selected'] = _descriptor(
          await markerIconCache.getCategoryMarker(
            category: cat,
            color: color,
            isSelected: true,
          ),
          _selectedSpotScale,
        );
      }

      // 3. User location
      icons['user_location'] = _descriptor(
        await markerIconCache.getUserLocationMarker(heading: 0.0),
        _userScale,
      );

      if (isClosed) return;
      _icons
        ..clear()
        ..addAll(icons);
    } catch (_) {
      // Ignore if the engine is tearing down.
    }
  }

  void _publishMarkers() {
    if (isClosed) return;
    markersNotifier.value = {
      if (_userMarker != null) _userMarker!,
      ..._spotMarkers,
    };
  }

  Marker? _buildUserMarker() {
    final locState = locationCubit.state;
    final icon = _icons['user_location'];
    if (!locState.hasLocation || icon == null) return null;
    return Marker(
      markerId: const MarkerId(_userMarkerId),
      position: locState.latLng!,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      // Flat markers rotate with the map, so the cone keeps pointing at the
      // physical device heading without any bearing compensation.
      flat: true,
      rotation: locState.heading,
      // Lowest zIndex so spots always sit on top and receive taps.
      zIndex: 1,
    );
  }

  void _rebuildUserMarker() {
    if (isClosed || !_mapReady || _icons.isEmpty) return;
    _userMarker = _buildUserMarker();
    _publishMarkers();
  }

  void _rebuildMarkers() {
    if (isClosed || !_mapReady || _icons.isEmpty) return;

    final selected = state.selectedSpot;
    final isAdding = state.isAddingSpot;
    final editingId = state.editingSpot?.id;

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

    final markers = <Marker>{};
    for (final spot in spotsToRender) {
      // While editing, the center pin replaces the edited spot.
      if (isAdding && editingId != null && spot.id == editingId) continue;

      final isSelected = selected?.id == spot.id;
      final imageName = spot.isCar
          ? (isSelected ? 'car_pin_selected' : 'car_pin')
          : (isSelected
                ? 'category_${spot.category.name}_selected'
                : 'category_${spot.category.name}');
      final icon = _icons[imageName];
      if (icon == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId('spot_${spot.id}'),
          position: spot.latLng,
          icon: icon,
          // Anchor at the bottom so the tip sits exactly on the coordinates.
          anchor: const Offset(0.5, 1.0),
          // Dimmed while picking a point (taps are ignored in _handleSpotTapped).
          alpha: isAdding ? _inactiveMarkerOpacity : 1.0,
          // Selected spot sits topmost, then the car, then other spots.
          zIndex: isSelected ? 10 : (spot.isCar ? 8 : 4),
          onTap: () => _handleSpotTapped(spot.id),
        ),
      );
    }

    _spotMarkers = markers;
    _userMarker = _buildUserMarker();
    _publishMarkers();
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
      _animate(CameraUpdate.newLatLngZoom(spot.latLng, defaultZoom));
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
      _animate(CameraUpdate.newLatLngZoom(userPos, defaultZoom));
    } else {
      _hasCenteredOnUser = false;
      locationCubit.requestPermission();
    }
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    _locationSubscription?.cancel();
    _revealTimer?.cancel();
    nameController.dispose();
    markersNotifier.dispose();
    // The GoogleMap widget disposes its own controller.
    _mapController = null;
    return super.close();
  }
}