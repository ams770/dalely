import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../constants/spot_categories.dart';
import '../../constants/storage_keys.dart';
import '../../data/settings_repository.dart';
import '../../data/spots_repository.dart';
import '../../models/spot.dart';
import '../../services/home_widget_service.dart';
import '../../services/notification_service.dart';
import '../../utils/distance_formatter.dart';
import '../location/location_cubit.dart';
import 'spots_state.dart';

class SpotsCubit extends Cubit<SpotsState> {
  SpotsCubit({
    required this.spotsRepository,
    required this.settingsRepository,
    required this.homeWidgetService,
    required this.notificationService,
    this.locationCubit,
  }) : super(const SpotsState()) {
    _init();
  }

  final SpotsRepository spotsRepository;
  final SettingsRepository settingsRepository;
  final HomeWidgetService homeWidgetService;
  final NotificationService notificationService;
  final LocationCubit? locationCubit;

  StreamSubscription? _spotsSubscription;
  StreamSubscription? _locationSubscription;

  void _init() {
    final settings = settingsRepository.load();
    _loadFromRepository(favoriteSpotId: settings.favoriteSpotId);

    _spotsSubscription = spotsRepository.watch().listen((_) {
      if (!isClosed) {
        _loadFromRepository();
      }
    });

    if (locationCubit != null) {
      _locationSubscription = locationCubit!.stream.listen((locState) {
        if (!isClosed && state.car != null) {
          _syncParkingNotification(userPosition: locState.position);
        }
      });
    }
  }

  void _loadFromRepository({String? favoriteSpotId}) {
    final all = spotsRepository.getAll();
    Spot? car;
    final spots = <Spot>[];

    for (final spot in all) {
      if (spot.isCar) {
        car = spot;
      } else {
        spots.add(spot);
      }
    }

    // Sort newest spots first
    spots.sort((a, b) => b.savedAt.compareTo(a.savedAt));

    final favId = favoriteSpotId ?? state.favoriteSpotId;

    emit(
      state.copyWith(
        status: SpotsStatus.success,
        car: car,
        clearCar: car == null,
        spots: spots,
        favoriteSpotId: favId,
      ),
    );

    _syncWidgets();
    _syncParkingNotification();
  }

  Future<void> parkCar({
    required double latitude,
    required double longitude,
  }) async {
    final car = await spotsRepository.parkCar(
      latitude: latitude,
      longitude: longitude,
    );
    if (isClosed) return;
    emit(state.copyWith(car: car));
    _syncWidgets();
    await notificationService.requestPermission();
    if (!isClosed) {
      _syncParkingNotification();
    }
  }

  Future<void> clearCar() async {
    await spotsRepository.delete(StorageKeys.carId);
    if (isClosed) return;
    emit(state.copyWith(clearCar: true));
    _syncWidgets();
    unawaited(notificationService.cancelParkingNotification());
  }

  Future<Spot> saveSpot({
    required String name,
    required SpotCategory category,
    required double latitude,
    required double longitude,
  }) async {
    if (category == SpotCategory.car) {
      final car = await spotsRepository.parkCar(
        latitude: latitude,
        longitude: longitude,
      );
      if (!isClosed) {
        emit(state.copyWith(car: car));
        _syncWidgets();
        await notificationService.requestPermission();
        if (!isClosed) {
          _syncParkingNotification();
        }
      }
      return car;
    }

    final spot = Spot(
      id: spotsRepository.newId(),
      name: name.trim(),
      category: category,
      latitude: latitude,
      longitude: longitude,
      savedAt: DateTime.now(),
    );

    await spotsRepository.save(spot);
    return spot;
  }

  Future<void> updateSpot(Spot spot) async {
    await spotsRepository.save(spot);
  }

  Future<void> renameSpot({
    required String id,
    required String newName,
  }) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;

    final existing = spotsRepository.getById(id);
    if (existing == null) return;

    final updated = existing.copyWith(name: clean);
    await spotsRepository.save(updated);
  }

  Future<void> deleteSpot(String id) async {
    await spotsRepository.delete(id);
    if (id == StorageKeys.carId) {
      unawaited(notificationService.cancelParkingNotification());
    }
    if (state.favoriteSpotId == id) {
      await setFavoriteSpot(null);
    }
  }

  Future<void> restoreSpot(Spot spot) async {
    await spotsRepository.save(spot);
    if (spot.isCar) {
      _syncParkingNotification();
    }
  }

  Future<void> setFavoriteSpot(String? id) async {
    await settingsRepository.setFavoriteSpotId(id);
    if (isClosed) return;
    emit(state.copyWith(favoriteSpotId: id, clearFavorite: id == null));
    _syncWidgets();
  }

  void _syncWidgets() {
    homeWidgetService.syncWidgetData(
      car: state.car,
      favoriteSpot: state.favoriteSpot,
    );
  }

  void _syncParkingNotification({Position? userPosition}) {
    final car = state.car;
    if (car == null) {
      notificationService.cancelParkingNotification();
      return;
    }

    final pos = userPosition ?? locationCubit?.state.position;
    String title = '🚗 Parked Car';
    String distanceText = 'Live tracking active • Tap to open on map';
    if (pos != null) {
      final meters = DistanceFormatter.calculateDistance(
        startLatitude: pos.latitude,
        startLongitude: pos.longitude,
        endLatitude: car.latitude,
        endLongitude: car.longitude,
      );
      final formatted = DistanceFormatter.formatShort(meters);
      title = '🚗 $formatted away';
      distanceText = 'Parked car • Tap to view on map or mark found';
    }

    notificationService.showParkingNotification(
      savedAt: car.savedAt,
      title: title,
      distanceText: distanceText,
    );
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    _locationSubscription?.cancel();
    return super.close();
  }
}
