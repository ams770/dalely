import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/car_tracking_state.dart';
import '../../models/spot.dart';
import '../../services/car_tracking_service.dart';
import '../../utils/car_tracking_calculator.dart';

/// Cubit managing active car walking tracking state, coordinating with [CarTrackingService].
class CarTrackingCubit extends Cubit<CarTrackingState> {
  CarTrackingCubit({
    required CarTrackingService carTrackingService,
  })  : _service = carTrackingService,
        super(const CarTrackingState()) {
    _subscription = _service.stateStream.listen(
      _handleStateUpdate,
      onError: _handleError,
    );
  }

  final CarTrackingService _service;
  StreamSubscription<CarTrackingState>? _subscription;
  Timer? _arrivalTimeoutTimer;

  static const Duration arrivalAutoStopDuration = Duration(minutes: 2);

  void _handleStateUpdate(CarTrackingState update) {
    if (isClosed) return;

    // Manage 2-minute arrival auto-stop timer
    if (update.status == CarTrackingStatus.arrived &&
        state.status != CarTrackingStatus.arrived) {
      _arrivalTimeoutTimer?.cancel();
      _arrivalTimeoutTimer = Timer(arrivalAutoStopDuration, () {
        stopCarTracking();
      });
    } else if (update.status != CarTrackingStatus.arrived) {
      _arrivalTimeoutTimer?.cancel();
      _arrivalTimeoutTimer = null;
    }

    if (update.status == CarTrackingStatus.stopped) {
      emit(const CarTrackingState(status: CarTrackingStatus.idle));
      return;
    }

    emit(update);
  }

  void _handleError(dynamic error) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: CarTrackingStatus.idle,
        errorMessage: () => error.toString(),
      ),
    );
  }

  /// Starts live walking tracking to the car.
  ///
  /// Returns `false` if car distance is greater than 50 km or start failed.
  Future<bool> startCarTracking({
    required Spot car,
    double? currentLat,
    double? currentLng,
    bool isArabic = false,
  }) async {
    if (currentLat != null && currentLng != null) {
      final initialDistance = CarTrackingCalculator.calculateDistance(
        startLatitude: currentLat,
        startLongitude: currentLng,
        endLatitude: car.latitude,
        endLongitude: car.longitude,
      );

      if (CarTrackingCalculator.isTooFar(initialDistance)) {
        emit(
          state.copyWith(
            errorMessage: () => 'tooFar',
          ),
        );
        return false;
      }

      final isArrived = initialDistance <= 15.0;
      final walkMinutes = CarTrackingCalculator.calculateWalkMinutes(initialDistance);
      final formattedDist = CarTrackingCalculator.formatDistance(initialDistance, isArabic: isArabic);
      final formattedWalk = CarTrackingCalculator.formatWalkTime(walkMinutes, isArabic: isArabic);

      emit(
        CarTrackingState(
          status: isArrived ? CarTrackingStatus.arrived : CarTrackingStatus.walking,
          distanceMeters: initialDistance,
          walkMinutes: walkMinutes,
          progress: isArrived ? 1.0 : 0.0,
          formattedDistance: formattedDist,
          formattedWalkTime: formattedWalk,
          isArrived: isArrived,
        ),
      );
    } else {
      emit(
        const CarTrackingState(
          status: CarTrackingStatus.waitingForGps,
        ),
      );
    }

    final success = await _service.start(
      carLat: car.latitude,
      carLng: car.longitude,
      spotId: car.id,
      savedAt: car.savedAt,
      carName: car.name,
      isArabic: isArabic,
      userLat: currentLat,
      userLng: currentLng,
    );

    if (!success && !isClosed) {
      emit(const CarTrackingState(status: CarTrackingStatus.idle));
    }

    return success;
  }

  /// Stops live car walking tracking and dismisses notifications/Live Activity.
  Future<void> stopCarTracking() async {
    _arrivalTimeoutTimer?.cancel();
    _arrivalTimeoutTimer = null;
    await _service.stop();
    if (!isClosed) {
      emit(const CarTrackingState(status: CarTrackingStatus.idle));
    }
  }

  @override
  Future<void> close() {
    _arrivalTimeoutTimer?.cancel();
    _arrivalTimeoutTimer = null;
    _subscription?.cancel();
    return super.close();
  }
}
