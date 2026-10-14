import 'dart:math';

import 'package:feen/modules/spots_map/cubit/spots_map_cubit.dart';
import 'package:feen/modules/spots_map/cubit/spots_map_state.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/cubits/location/location_state.dart';
import 'package:feen/shared/cubits/spots/spots_cubit.dart';
import 'package:feen/shared/cubits/spots/spots_state.dart';
import 'package:feen/shared/models/location_access.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/services/marker_icon_cache.dart';
import 'package:feen/shared/theme/app_theme_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class _FakeMapLibrePlatform extends MapLibrePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit(
    List<Spot> initialSpots, {
    Spot? car,
    List<Spot>? parkingHistory,
  }) : super(SpotsState(
          spots: initialSpots,
          car: car,
          parkingHistory: parkingHistory ?? const [],
        ));

  Spot? lastSavedSpot;

  @override
  Future<Spot> saveSpot({
    required String name,
    required SpotCategory category,
    required double latitude,
    required double longitude,
  }) async {
    final spot = Spot(
      id: 'spot_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      latitude: latitude,
      longitude: longitude,
      savedAt: DateTime.now(),
    );
    lastSavedSpot = spot;
    emit(state.copyWith(spots: [...state.spots, spot]));
    return spot;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit({LatLng? userLatLng})
      : super(LocationState(
          access: LocationAccess.granted,
          position: userLatLng != null
              ? Position(
                  latitude: userLatLng.latitude,
                  longitude: userLatLng.longitude,
                  timestamp: DateTime.now(),
                  accuracy: 5.0,
                  altitude: 0.0,
                  altitudeAccuracy: 0.0,
                  heading: 0.0,
                  headingAccuracy: 0.0,
                  speed: 0.0,
                  speedAccuracy: 0.0,
                )
              : null,
        ));
  @override
  Future<LocationAccess> requestPermission() async => LocationAccess.granted;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SpotsMapUnifiedCubit - Single Map Architecture', () {
    late _FakeSpotsCubit fakeSpotsCubit;
    late _FakeLocationCubit fakeLocationCubit;
    late MarkerIconCache markerIconCache;
    const themeExtension = AppThemeExtension.light;

    setUp(() {
      final now = DateTime(2026, 10, 11);
      final spot1 = Spot(
        id: '1',
        name: 'Supermarket',
        category: SpotCategory.market,
        latitude: 30.05,
        longitude: 31.25,
        savedAt: now,
      );
      fakeSpotsCubit = _FakeSpotsCubit([spot1]);
      fakeLocationCubit = _FakeLocationCubit(
        userLatLng: const LatLng(30.0444, 31.2357),
      );
      markerIconCache = MarkerIconCache();
    });

    test('initializes in viewing mode with initial target from spot/user', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      expect(cubit.state.mode, SpotsMapMode.viewing);
      expect(cubit.state.isAddingSpot, isFalse);
      expect(cubit.state.category, SpotCategory.other);
      // Confirms camera target centers on user position when no spot is selected
      expect(cubit.state.initialTarget.latitude, closeTo(30.0444, 0.0001));
      expect(cubit.state.initialTarget.longitude, closeTo(31.2357, 0.0001));
      cubit.close();
    });

    test('recenterOnUser requests permission when location is null', () {
      final noLocCubit = _FakeLocationCubit();
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: noLocCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      cubit.recenterOnUser();
      expect(cubit.state.selectedSpot, isNull);
      cubit.close();
    });

    test('initializes directly in addSpot mode when launched from saveSpot route', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
        initialMode: SpotsMapMode.addSpot,
      );

      expect(cubit.state.mode, SpotsMapMode.addSpot);
      expect(cubit.state.isAddingSpot, isTrue);
      expect(cubit.state.pickedLocation.latitude, closeTo(30.0444, 0.0001));
      expect(cubit.state.pickedLocation.longitude, closeTo(31.2357, 0.0001));
      cubit.close();
    });

    test('transitions from viewing to addSpot mode and back seamlessly without rebuild', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      expect(cubit.state.isAddingSpot, isFalse);

      cubit.enterAddSpotMode(initialTarget: const LatLng(30.1, 31.3));
      expect(cubit.state.mode, SpotsMapMode.addSpot);
      expect(cubit.state.isAddingSpot, isTrue);
      expect(cubit.state.pickedLocation.latitude, closeTo(30.1, 0.0001));
      expect(cubit.state.pickedLocation.longitude, closeTo(31.3, 0.0001));

      cubit.exitAddSpotMode();
      expect(cubit.state.mode, SpotsMapMode.viewing);
      expect(cubit.state.isAddingSpot, isFalse);

      cubit.close();
    });

    test('onMapLongClick enters addSpot mode with clicked location', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      expect(cubit.state.isAddingSpot, isFalse);

      cubit.onMapLongClick(const LatLng(29.98, 31.25));
      expect(cubit.state.mode, SpotsMapMode.addSpot);
      expect(cubit.state.isAddingSpot, isTrue);
      expect(cubit.state.pickedLocation.latitude, closeTo(29.98, 0.0001));
      expect(cubit.state.pickedLocation.longitude, closeTo(31.25, 0.0001));

      cubit.close();
    });

    test('updatePinScreenMetrics correctly computes pinScreenPoint and pinCenterOffsetDy', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      // Suppose screen is 400x800, topPadding is 100, bottomPadding is 300
      cubit.updatePinScreenMetrics(
        topPadding: 100,
        bottomPadding: 300,
        screenWidth: 400,
        screenHeight: 800,
      );

      // Pin center y = 100 + (800 - 100 - 300) / 2 = 100 + 200 = 300
      // Pin center x = 400 / 2 = 200
      expect(cubit.pinScreenPoint, const Point<double>(200, 300));

      // Screen center is (200, 400)
      expect(cubit.screenCenterPoint, const Point<double>(200, 400));

      // Offset dy = 400 - 300 = 100
      expect(cubit.pinCenterOffsetDy, 100.0);

      cubit.close();
    });

    test('onMapLongClick with screenPoint forwards touch coordinates', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      cubit.onMapLongClick(
        const LatLng(30.05, 31.25),
        screenPoint: const Point<double>(150, 450),
      );

      expect(cubit.state.mode, SpotsMapMode.addSpot);
      expect(cubit.state.isAddingSpot, isTrue);
      expect(cubit.state.pickedLocation.latitude, closeTo(30.05, 0.0001));
      expect(cubit.state.pickedLocation.longitude, closeTo(31.25, 0.0001));

      cubit.close();
    });

    test('onMapLongClick while already in addSpot mode updates picked location to newly clicked point', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      // First long click
      cubit.onMapLongClick(const LatLng(30.0, 31.0));
      expect(cubit.state.isAddingSpot, isTrue);
      expect(cubit.state.pickedLocation.latitude, closeTo(30.0, 0.0001));
      expect(cubit.state.pickedLocation.longitude, closeTo(31.0, 0.0001));

      // Second long click on a different point while addSpot mode is open
      cubit.onMapLongClick(
        const LatLng(30.5, 31.5),
        screenPoint: const Point<double>(210, 520),
      );
      expect(cubit.state.isAddingSpot, isTrue);
      expect(cubit.state.pickedLocation.latitude, closeTo(30.5, 0.0001));
      expect(cubit.state.pickedLocation.longitude, closeTo(31.5, 0.0001));

      cubit.close();
    });

    test('enterAddSpotMode with null initialTarget uses current camera center and does not reset to user location', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      // Simulate user panning the camera to a custom location while viewing
      cubit.onCameraMove(const CameraPosition(
        target: LatLng(31.2001, 29.9187), // Alexandria
        zoom: 15.0,
      ));

      // User clicks "Add spot" button (initialTarget is null)
      cubit.enterAddSpotMode();

      expect(cubit.state.mode, SpotsMapMode.addSpot);
      expect(cubit.state.isAddingSpot, isTrue);
      // Pin is placed at the current camera center, NOT the user's GPS location (30.0444, 31.2357)
      expect(cubit.state.pickedLocation.latitude, closeTo(31.2001, 0.0001));
      expect(cubit.state.pickedLocation.longitude, closeTo(29.9187, 0.0001));

      cubit.close();
    });

    test('cancelling addSpot mode preserves camera position and prevents unwanted auto-center on subsequent location updates', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      // Long click at custom point
      cubit.onMapLongClick(const LatLng(29.98, 31.25));
      expect(cubit.state.isAddingSpot, isTrue);

      // User cancels / exits add spot mode
      cubit.exitAddSpotMode();
      expect(cubit.state.mode, SpotsMapMode.viewing);
      expect(cubit.state.isAddingSpot, isFalse);

      // Emit new location updates
      fakeLocationCubit.emit(LocationState(
        access: LocationAccess.granted,
        position: Position(
          latitude: 30.0500,
          longitude: 31.2400,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      ));

      // State remains in viewing mode without forced selection or disruption
      expect(cubit.state.isAddingSpot, isFalse);
      expect(cubit.state.selectedSpot, isNull);

      cubit.close();
    });

    test('saves spot, updates SpotsCubit, exits addSpot mode and selects new spot on same map', () async {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      cubit.enterAddSpotMode(initialTarget: const LatLng(30.15, 31.35));
      cubit.setCategory(SpotCategory.pharmacy);
      cubit.nameController.text = 'El Ezaby Pharmacy';

      expect(cubit.state.canSave, isTrue);
      expect(cubit.state.spotName, 'El Ezaby Pharmacy');
      expect(cubit.state.category, SpotCategory.pharmacy);

      final saved = await cubit.saveCurrentSpot();
      expect(saved, isNotNull);
      expect(saved!.name, 'El Ezaby Pharmacy');
      expect(saved.category, SpotCategory.pharmacy);
      expect(fakeSpotsCubit.lastSavedSpot?.name, 'El Ezaby Pharmacy');

      // Returns to viewing mode with the new spot selected on the SAME map
      expect(cubit.state.mode, SpotsMapMode.viewing);
      expect(cubit.state.isAddingSpot, isFalse);
      expect(cubit.state.selectedSpot, saved);

      cubit.close();
    });

    test('selectSpotById automatically exits addSpot mode if active', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
        initialMode: SpotsMapMode.addSpot,
      );

      expect(cubit.state.isAddingSpot, isTrue);

      cubit.selectSpotById('1');
      expect(cubit.state.isAddingSpot, isFalse);
      expect(cubit.state.selectedSpot?.id, '1');

      cubit.close();
    });

    test('initializes with isMapReady true immediately in light mode', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
        isDarkMode: false,
      );

      expect(cubit.state.isMapReady, isTrue);
      cubit.close();
    });

    test('initializes with isMapReady false in dark mode until map is ready', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
        isDarkMode: true,
      );

      expect(cubit.state.isMapReady, isFalse);
      cubit.close();
    });

    test('updateTheme updates theme state and dark mode status', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
        isDarkMode: false,
      );

      expect(cubit.isDarkMode, isFalse);

      const darkThemeExtension = AppThemeExtension.dark;
      cubit.updateTheme(isDarkMode: true, themeExtension: darkThemeExtension);

      expect(cubit.isDarkMode, isTrue);
      expect(cubit.themeExtension, darkThemeExtension);

      cubit.close();
    });

    test('close completes safely without exception even if MapLibreMapController was already disposed', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      final controller = MapLibreMapController(
        maplibrePlatform: _FakeMapLibrePlatform(),
        annotationOrder: const [],
        annotationConsumeTapEvents: const [],
      );

      cubit.onMapCreated(controller);
      // Simulate widget tree unmounting and MapLibreMap disposing its controller
      controller.dispose();

      // Now when BlocProvider unmounts and calls cubit.close(), it should NOT throw
      expect(() => cubit.close(), returnsNormally);
    });

    test('updatePinScreenMetrics updates metrics and computes accurate pinScreenPoint', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
      );

      cubit.updatePinScreenMetrics(
        topPadding: 80.0,
        bottomPadding: 300.0,
        screenWidth: 400.0,
        screenHeight: 800.0,
        devicePixelRatio: 2.5,
      );

      // x = screenWidth / 2 = 200.0
      // y = topPadding + (screenHeight - topPadding - bottomPadding) / 2 = 80 + (800 - 80 - 300) / 2 = 80 + 210 = 290.0
      expect(cubit.pinScreenPoint, const Point<double>(200.0, 290.0));
      expect(cubit.screenCenterPoint, const Point<double>(200.0, 400.0));
      expect(cubit.pinCenterOffsetDy, 400.0 - 290.0);

      cubit.close();
    });

    test('onlyShowSpotId isolates single spot on the map and clearing selection restores all spots', () {
      final cubit = SpotsMapCubit(
        spotsCubit: fakeSpotsCubit,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
        onlyShowSpotId: '1',
      );

      expect(cubit.state.onlyShowSpotId, '1');
      expect(cubit.state.selectedSpot?.id, '1');

      // Deselecting spot clears onlyShowSpotId
      cubit.selectSpot(null);
      expect(cubit.state.onlyShowSpotId, isNull);
      expect(cubit.state.selectedSpot, isNull);

      // Re-selecting with onlyShowSpot: true re-engages isolation
      cubit.selectSpotById('1', onlyShowSpot: true);
      expect(cubit.state.onlyShowSpotId, '1');
      expect(cubit.state.selectedSpot?.id, '1');

      cubit.close();
    });

    test('compass rotation cancels map bearing so cone matches device heading', () {
      // Test formula: ((heading - bearing) % 360 + 360) % 360
      double computeIconRotate(double heading, double bearing) =>
          ((heading - bearing) % 360 + 360) % 360;

      // 1. Map not rotated (bearing 0): iconRotate equals heading
      expect(computeIconRotate(45.0, 0.0), 45.0);
      expect(computeIconRotate(0.0, 0.0), 0.0);

      // 2. Map rotated clockwise by 30°: bearing = 30°
      expect(computeIconRotate(90.0, 30.0), 60.0);

      // 3. Map rotated clockwise past heading: (30 - 90) = -60 -> 300°
      expect(computeIconRotate(30.0, 90.0), 300.0);

      // 4. Map rotated full circle wrapping: (10 - 350) = -340 -> 20°
      expect(computeIconRotate(10.0, 350.0), 20.0);
    });

    test('parking history spot can be selected and isolated with onlyShowSpotId without disappearing', () {
      final historySpot = Spot(
        id: 'car_history_123',
        name: '',
        category: SpotCategory.car,
        latitude: 30.05,
        longitude: 31.05,
        savedAt: DateTime.now(),
        status: SpotStatus.found,
      );

      final spotsCubitWithHistory = _FakeSpotsCubit(
        const [],
        parkingHistory: [historySpot],
      );

      final cubit = SpotsMapCubit(
        spotsCubit: spotsCubitWithHistory,
        locationCubit: fakeLocationCubit,
        markerIconCache: markerIconCache,
        themeExtension: themeExtension,
        initialSelectedSpotId: 'car_history_123',
        onlyShowSpotId: 'car_history_123',
      );

      // Spot is identified from parkingHistory
      expect(cubit.state.selectedSpot?.id, 'car_history_123');
      expect(cubit.state.onlyShowSpotId, 'car_history_123');

      // Calling selectSpotById with onlyShowSpot: true keeps onlyShowSpotId intact
      cubit.selectSpotById('car_history_123', onlyShowSpot: true);
      expect(cubit.state.selectedSpot?.id, 'car_history_123');
      expect(cubit.state.onlyShowSpotId, 'car_history_123');

      cubit.close();
      spotsCubitWithHistory.close();
    });
  });
}
