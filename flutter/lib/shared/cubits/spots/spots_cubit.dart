import 'dart:async';
import 'package:flutter/widgets.dart';
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
import '../car_tracking/car_tracking_cubit.dart';
import '../location/location_cubit.dart';
import 'spots_state.dart';

class SpotsCubit extends Cubit<SpotsState> {
  SpotsCubit({
    required this.spotsRepository,
    required this.settingsRepository,
    required this.homeWidgetService,
    required this.notificationService,
    this.locationCubit,
    this.carTrackingCubit,
  }) : super(const SpotsState()) {
    _init();
  }

  final SpotsRepository spotsRepository;
  final SettingsRepository settingsRepository;
  final HomeWidgetService homeWidgetService;
  final NotificationService notificationService;
  final LocationCubit? locationCubit;
  final CarTrackingCubit? carTrackingCubit;

  StreamSubscription? _spotsSubscription;
  StreamSubscription? _locationSubscription;
  double? _lastNotifiedDistance;

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
          final pos = locState.position;
          if (pos != null) {
            final car = state.car!;
            final currentDist = DistanceFormatter.calculateDistance(
              startLatitude: pos.latitude,
              startLongitude: pos.longitude,
              endLatitude: car.latitude,
              endLongitude: car.longitude,
            );
            if (_lastNotifiedDistance == null ||
                (currentDist - _lastNotifiedDistance!).abs() >= 15.0) {
              _lastNotifiedDistance = currentDist;
              _syncParkingNotification(
                userPosition: pos,
                showBannerOnIos: false,
              );
            }
          }
        }
        if (!isClosed && state.sortOrder == SpotSortOrder.nearest) {
          final sorted = List<Spot>.from(state.spots);
          _sortSpots(sorted, SpotSortOrder.nearest);
          emit(state.copyWith(spots: sorted));
        }
      });
    }
  }

  void _loadFromRepository({String? favoriteSpotId}) {
    final all = spotsRepository.getAll();
    Spot? car;
    final spots = <Spot>[];
    final parkingHistory = <Spot>[];

    for (final spot in all) {
      if (spot.id == StorageKeys.carId && spot.status != SpotStatus.found) {
        car = spot;
      } else if (spot.status == SpotStatus.found ||
          (spot.category == SpotCategory.car &&
              spot.id != StorageKeys.carId)) {
        parkingHistory.add(spot);
      } else {
        spots.add(spot);
      }
    }

    _sortSpots(spots, state.sortOrder);
    parkingHistory.sort((a, b) => b.savedAt.compareTo(a.savedAt));

    final favId = favoriteSpotId ?? state.favoriteSpotId;

    emit(
      state.copyWith(
        status: SpotsStatus.success,
        car: car,
        clearCar: car == null,
        spots: spots,
        parkingHistory: parkingHistory,
        favoriteSpotId: favId,
      ),
    );

    _syncWidgets();
    _syncParkingNotification(showBannerOnIos: false);
  }

  void _sortSpots(List<Spot> list, SpotSortOrder order) {
    switch (order) {
      case SpotSortOrder.dateDesc:
        list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        break;
      case SpotSortOrder.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case SpotSortOrder.category:
        list.sort((a, b) {
          final cmp = a.category.name.compareTo(b.category.name);
          return cmp != 0
              ? cmp
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case SpotSortOrder.nearest:
        final pos = locationCubit?.state.position;
        if (pos != null) {
          double dist(Spot s) => DistanceFormatter.calculateDistance(
                startLatitude: pos.latitude,
                startLongitude: pos.longitude,
                endLatitude: s.latitude,
                endLongitude: s.longitude,
              );
          list.sort((a, b) => dist(a).compareTo(dist(b)));
        } else {
          list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        }
        break;
    }
  }

  void setSortOrder(SpotSortOrder order) {
    if (order == state.sortOrder) return;
    if (order == SpotSortOrder.nearest &&
        (locationCubit == null || !locationCubit!.state.hasLocation)) {
      locationCubit?.requestPermission();
    }
    final sorted = List<Spot>.from(state.spots);
    _sortSpots(sorted, order);
    emit(state.copyWith(sortOrder: order, spots: sorted));
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
    _lastNotifiedDistance = null;
    emit(state.copyWith(car: car));
    _syncWidgets();
    await notificationService.requestPermission();
    if (!isClosed) {
      _syncParkingNotification(showBannerOnIos: true);
    }
  }

  Future<void> clearCar() async {
    _lastNotifiedDistance = null;
    final currentCar = state.car;
    emit(state.copyWith(clearCar: true));
    if (currentCar != null) {
      final now = DateTime.now();
      final duration = now.difference(currentCar.savedAt);
      final historyId =
          'car_history_${currentCar.savedAt.millisecondsSinceEpoch}_${now.millisecondsSinceEpoch}';
      final foundCar = currentCar.copyWith(
        id: historyId,
        status: SpotStatus.found,
        parkedDuration: duration,
      );
      await spotsRepository.delete(StorageKeys.carId);
      await spotsRepository.save(foundCar);
    }
    if (isClosed) return;
    _syncWidgets();
    await carTrackingCubit?.stopCarTracking();
    unawaited(notificationService.cancelParkingNotification());
  }

  Future<void> clearParkingHistory() async {
    for (final spot in state.parkingHistory) {
      await spotsRepository.delete(spot.id);
    }
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
        _lastNotifiedDistance = null;
        emit(state.copyWith(car: car));
        _syncWidgets();
        await notificationService.requestPermission();
        if (!isClosed) {
          _syncParkingNotification(showBannerOnIos: true);
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
      _lastNotifiedDistance = null;
      unawaited(notificationService.cancelParkingNotification());
    }
    if (state.favoriteSpotId == id) {
      await setFavoriteSpot(null);
    }
  }

  Future<void> restoreSpot(Spot spot) async {
    if (spot.isCar) {
      await spotsRepository.delete(spot.id);
      final activeCar = spot.copyWith(
        id: StorageKeys.carId,
        status: SpotStatus.parking,
      );
      await spotsRepository.save(activeCar);
      _lastNotifiedDistance = null;
      _syncParkingNotification(showBannerOnIos: true);
    } else {
      await spotsRepository.save(spot);
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

  void _syncParkingNotification({
    Position? userPosition,
    bool showBannerOnIos = false,
  }) {
    final car = state.car;
    if (car == null || car.status == SpotStatus.found) {
      notificationService.cancelParkingNotification();
      carTrackingCubit?.stopCarTracking();
      return;
    }

    final settings = settingsRepository.load();
    if (!settings.carDistanceNotificationEnabled) {
      notificationService.cancelParkingNotification();
      carTrackingCubit?.stopCarTracking();
      return;
    }

    // Cancel legacy flutter_local_notifications (ID 1001) so it never appears
    notificationService.cancelParkingNotification();

    final pos = userPosition ?? locationCubit?.state.position;
    final bool isArabic;
    if (settings.localeCode != null) {
      isArabic = settings.localeCode!.startsWith('ar');
    } else {
      final deviceLanguage =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      isArabic = deviceLanguage == 'ar';
    }

    carTrackingCubit?.startCarTracking(
      car: car,
      currentLat: pos?.latitude,
      currentLng: pos?.longitude,
      isArabic: isArabic,
    );
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    _locationSubscription?.cancel();
    return super.close();
  }
}
