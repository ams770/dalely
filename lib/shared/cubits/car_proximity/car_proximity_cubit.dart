import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/spot.dart';
import '../../utils/distance_formatter.dart';
import 'car_proximity_state.dart';

/// Manages car proximity tracking and arrival notifications.
///
/// Ensures arrival dialogs trigger only after the user has left the car area
/// (>= 15m) and then returned to within threshold (<= 5m or <= 1m).
class CarProximityCubit extends Cubit<CarProximityState> {
  CarProximityCubit() : super(const CarProximityState());

  static const double awayThresholdMeters = 15.0;

  void checkProximity({
    required Spot? car,
    required double? userLatitude,
    required double? userLongitude,
  }) {
    if (car == null) {
      if (state.hasMovedAway ||
          state.shouldShowDialog ||
          state.isDialogVisible ||
          state.lastCarSavedAt != null) {
        emit(const CarProximityState());
      }
      return;
    }

    // Detect new parking session
    final isNewParking = state.lastCarSavedAt == null ||
        car.savedAt.isAfter(state.lastCarSavedAt!);
    if (isNewParking) {
      emit(CarProximityState(lastCarSavedAt: car.savedAt));
      return;
    }

    if (userLatitude == null || userLongitude == null) return;

    final distance = DistanceFormatter.calculateDistance(
      startLatitude: userLatitude,
      startLongitude: userLongitude,
      endLatitude: car.latitude,
      endLongitude: car.longitude,
    );

    if (!state.hasMovedAway) {
      if (distance >= awayThresholdMeters) {
        emit(state.copyWith(
          hasMovedAway: true,
          distanceToCar: () => distance,
        ));
      } else {
        emit(state.copyWith(distanceToCar: () => distance));
      }
    } else {
      if (!state.isDialogVisible && !state.shouldShowDialog) {
        if (distance <= state.targetThresholdMeters) {
          emit(state.copyWith(
            shouldShowDialog: true,
            distanceToCar: () => distance,
          ));
        } else {
          emit(state.copyWith(distanceToCar: () => distance));
        }
      } else {
        emit(state.copyWith(distanceToCar: () => distance));
      }
    }
  }

  void onDialogOpened() {
    emit(state.copyWith(isDialogVisible: true, shouldShowDialog: false));
  }

  void onCantSeeCar() {
    emit(state.copyWith(
      isDialogVisible: false,
      shouldShowDialog: false,
      targetThresholdMeters: 1.0,
    ));
  }

  void onFoundCar() {
    emit(const CarProximityState());
  }

  void onDialogDismissed() {
    emit(state.copyWith(isDialogVisible: false, shouldShowDialog: false));
  }
}
