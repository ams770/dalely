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
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit(List<Spot> initialSpots, {Spot? car})
      : super(SpotsState(spots: initialSpots, car: car));

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
      expect(cubit.state.category, SpotCategory.market);
      // Confirms camera target centers on user position when no spot is selected
      expect(cubit.state.initialTarget.latitude, 30.0444);
      expect(cubit.state.initialTarget.longitude, 31.2357);
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
      expect(cubit.state.pickedLocation.latitude, 30.0444);
      expect(cubit.state.pickedLocation.longitude, 31.2357);
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
      expect(cubit.state.pickedLocation.latitude, 30.1);
      expect(cubit.state.pickedLocation.longitude, 31.3);

      cubit.exitAddSpotMode();
      expect(cubit.state.mode, SpotsMapMode.viewing);
      expect(cubit.state.isAddingSpot, isFalse);

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
  });
}
