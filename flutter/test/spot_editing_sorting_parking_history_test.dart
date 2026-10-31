import 'dart:async';

import 'package:feen/modules/spots_map/cubit/spots_map_cubit.dart';
import 'package:feen/modules/spots_map/cubit/spots_map_state.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/constants/storage_keys.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/cubits/location/location_state.dart';
import 'package:feen/shared/cubits/spots/spots_cubit.dart';
import 'package:feen/shared/cubits/spots/spots_state.dart';
import 'package:feen/shared/data/settings_repository.dart';
import 'package:feen/shared/data/spots_repository.dart';
import 'package:feen/shared/models/app_settings.dart';
import 'package:feen/shared/models/location_access.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';
import 'package:feen/shared/services/home_widget_service.dart';
import 'package:feen/shared/services/marker_icon_cache.dart';
import 'package:feen/shared/services/notification_service.dart';
import 'package:feen/shared/theme/app_theme_extension.dart';
import 'package:feen/shared/utils/duration_formatter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeSpotsRepository implements SpotsRepository {
  final Map<String, Spot> _data = {};
  final StreamController<List<Spot>> _controller =
      StreamController<List<Spot>>.broadcast();

  @override
  List<Spot> getAll() => _data.values.toList(growable: false);

  @override
  Spot? getById(String id) => _data[id];

  @override
  Stream<List<Spot>> watch() => _controller.stream;

  @override
  Future<void> save(Spot spot) async {
    _data[spot.id] = spot;
    _controller.add(getAll());
  }

  @override
  Future<void> delete(String id) async {
    _data.remove(id);
    _controller.add(getAll());
  }

  @override
  Future<Spot> parkCar({
    required double latitude,
    required double longitude,
  }) async {
    final car = Spot(
      id: StorageKeys.carId,
      name: '',
      category: SpotCategory.car,
      latitude: latitude,
      longitude: longitude,
      savedAt: DateTime.now(),
      status: SpotStatus.parking,
    );
    _data[StorageKeys.carId] = car;
    _controller.add(getAll());
    return car;
  }

  @override
  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  AppSettings load() => _settings;

  @override
  Future<AppSettings> setFavoriteSpotId(String? id) async {
    _settings = _settings.copyWith(favoriteSpotId: () => id);
    return _settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHomeWidgetService implements HomeWidgetService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeNotificationService implements NotificationService {
  @override
  Future<bool> requestPermission() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit({LatLng? userLatLng})
    : super(
        LocationState(
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
        ),
      );

  void setPosition(double lat, double lng) {
    emit(
      state.copyWith(
        access: LocationAccess.granted,
        position: Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeSpotsRepository spotsRepository;
  late _FakeSettingsRepository settingsRepository;
  late _FakeHomeWidgetService homeWidgetService;
  late _FakeNotificationService notificationService;
  late _FakeLocationCubit locationCubit;
  late SpotsCubit spotsCubit;

  setUp(() {
    spotsRepository = _FakeSpotsRepository();
    settingsRepository = _FakeSettingsRepository();
    homeWidgetService = _FakeHomeWidgetService();
    notificationService = _FakeNotificationService();
    locationCubit = _FakeLocationCubit(userLatLng: const LatLng(30.0, 31.0));
    spotsCubit = SpotsCubit(
      spotsRepository: spotsRepository,
      settingsRepository: settingsRepository,
      homeWidgetService: homeWidgetService,
      notificationService: notificationService,
      locationCubit: locationCubit,
    );
  });

  tearDown(() async {
    await spotsCubit.close();
    await locationCubit.close();
  });

  group('Spot Editing via SpotsMapCubit', () {
    test('initializes with editingSpot and updates spot on save', () async {
      final existingSpot = Spot(
        id: 'spot_1',
        name: 'Original Pharmacy',
        category: SpotCategory.pharmacy,
        latitude: 30.05,
        longitude: 31.25,
        savedAt: DateTime(2026, 1, 1),
      );
      await spotsRepository.save(existingSpot);
      await Future<void>.delayed(Duration.zero);

      final mapCubit = SpotsMapCubit(
        spotsCubit: spotsCubit,
        locationCubit: locationCubit,
        markerIconCache: MarkerIconCache(),
        themeExtension: AppThemeExtension.light,
        isDarkMode: false,
        editingSpot: existingSpot,
      );

      expect(mapCubit.state.mode, SpotsMapMode.addSpot);
      expect(mapCubit.state.isEditingSpot, isTrue);
      expect(mapCubit.state.editingSpot, existingSpot);
      expect(mapCubit.state.spotName, 'Original Pharmacy');
      expect(mapCubit.state.category, SpotCategory.pharmacy);
      expect(mapCubit.state.pickedLocation, const LatLng(30.05, 31.25));

      // Modify fields
      mapCubit.nameController.text = 'Updated Pharmacy';
      mapCubit.setCategory(SpotCategory.hospital);

      final updatedSpot = await mapCubit.saveCurrentSpot();
      expect(updatedSpot, isNotNull);
      expect(updatedSpot!.id, 'spot_1');
      expect(updatedSpot.name, 'Updated Pharmacy');
      expect(updatedSpot.category, SpotCategory.hospital);

      // Verify in spotsCubit
      final stored = spotsCubit.state.spots.firstWhere((s) => s.id == 'spot_1');
      expect(stored.name, 'Updated Pharmacy');
      expect(stored.category, SpotCategory.hospital);

      await mapCubit.close();
    });
  });

  group('Spot Sorting in SpotsCubit', () {
    test('sorts by dateDesc, nearest, category, and name', () async {
      final s1 = Spot(
        id: 's1',
        name: 'Zebra Market',
        category: SpotCategory.market,
        latitude: 30.1, // ~11 km away from 30.0, 31.0
        longitude: 31.0,
        savedAt: DateTime(2026, 1, 1),
      );
      final s2 = Spot(
        id: 's2',
        name: 'Alpha Gym',
        category: SpotCategory.gym,
        latitude: 30.01, // ~1 km away from 30.0, 31.0
        longitude: 31.0,
        savedAt: DateTime(2026, 1, 3),
      );
      final s3 = Spot(
        id: 's3',
        name: 'Beta Pharmacy',
        category: SpotCategory.pharmacy,
        latitude: 30.05, // ~5.5 km away from 30.0, 31.0
        longitude: 31.0,
        savedAt: DateTime(2026, 1, 2),
      );

      await spotsRepository.save(s1);
      await spotsRepository.save(s2);
      await spotsRepository.save(s3);
      await Future<void>.delayed(Duration.zero);

      // 1. dateDesc
      spotsCubit.setSortOrder(SpotSortOrder.dateDesc);
      expect(spotsCubit.state.spots.map((s) => s.id).toList(), [
        's2',
        's3',
        's1',
      ]);

      // 2. nearest (user at 30.0, 31.0)
      spotsCubit.setSortOrder(SpotSortOrder.nearest);
      expect(spotsCubit.state.spots.map((s) => s.id).toList(), [
        's2',
        's3',
        's1',
      ]);

      // Move user closer to s1
      locationCubit.setPosition(30.11, 31.0);
      await Future<void>.delayed(Duration.zero);
      // Triggers resort
      expect(spotsCubit.state.spots.map((s) => s.id).toList(), [
        's1',
        's3',
        's2',
      ]);

      // 3. name
      spotsCubit.setSortOrder(SpotSortOrder.name);
      expect(spotsCubit.state.spots.map((s) => s.id).toList(), [
        's2',
        's3',
        's1',
      ]); // Alpha, Beta, Zebra

      // 4. category
      spotsCubit.setSortOrder(SpotSortOrder.category);
      expect(spotsCubit.state.spots.map((s) => s.category.name).toList(), [
        SpotCategory.gym.name,
        SpotCategory.market.name,
        SpotCategory.pharmacy.name,
      ]);
    });
  });

  group('Parking Status & History', () {
    test('parkCar sets status to parking, clearCar moves to history with status found', () async {
      await spotsCubit.parkCar(latitude: 30.05, longitude: 31.05);

      expect(spotsCubit.state.car, isNotNull);
      expect(spotsCubit.state.car!.status, SpotStatus.parking);
      expect(spotsCubit.state.car!.isParking, isTrue);
      expect(spotsCubit.state.parkingHistory, isEmpty);

      // User clears car (found)
      await spotsCubit.clearCar();

      expect(spotsCubit.state.car, isNull);
      expect(spotsCubit.state.parkingHistory.length, 1);
      final archived = spotsCubit.state.parkingHistory.first;
      expect(archived.status, SpotStatus.found);
      expect(archived.isFound, isTrue);
      expect(archived.latitude, 30.05);
      expect(archived.longitude, 31.05);
      expect(archived.parkedDuration, isNotNull);
      expect(
        archived.calculatedParkedDuration,
        greaterThanOrEqualTo(Duration.zero),
      );

      // Undo / restore spot
      await spotsCubit.restoreSpot(archived);
      expect(spotsCubit.state.car, isNotNull);
      expect(spotsCubit.state.car!.status, SpotStatus.parking);
      expect(spotsCubit.state.parkingHistory, isEmpty);

      // Clear again then clearParkingHistory
      await spotsCubit.clearCar();
      expect(spotsCubit.state.parkingHistory.length, 1);
      await spotsCubit.clearParkingHistory();
      expect(spotsCubit.state.parkingHistory, isEmpty);
    });
  });

  group('DurationFormatter.formatHuman', () {
    test('formats durations in English correctly', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        DurationFormatter.formatHuman(const Duration(seconds: 15), l10n),
        'Less than a minute',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(minutes: 1), l10n),
        '1 minute',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(minutes: 2), l10n),
        '2 minutes',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(minutes: 45), l10n),
        '45 minutes',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(hours: 1), l10n),
        '1 hour',
      );
      expect(
        DurationFormatter.formatHuman(
          const Duration(hours: 2, minutes: 15),
          l10n,
        ),
        '2 hours, 15 minutes',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(days: 1), l10n),
        '1 day',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(days: 2, hours: 3), l10n),
        '2 days, 3 hours',
      );
    });

    test('formats durations in Arabic correctly', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      expect(
        DurationFormatter.formatHuman(const Duration(seconds: 15), l10n),
        'أقل من دقيقة',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(minutes: 1), l10n),
        'دقيقة',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(minutes: 2), l10n),
        'دقيقتين',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(minutes: 5), l10n),
        '5 دقائق',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(minutes: 15), l10n),
        '15 دقيقة',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(hours: 1), l10n),
        'ساعة',
      );
      expect(
        DurationFormatter.formatHuman(
          const Duration(hours: 2, minutes: 15),
          l10n,
        ),
        'ساعتين و15 دقيقة',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(days: 1), l10n),
        'يوم',
      );
      expect(
        DurationFormatter.formatHuman(const Duration(days: 2, hours: 3), l10n),
        'يومين و3 ساعات',
      );
    });
  });
}
