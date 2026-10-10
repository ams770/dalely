import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/spot.dart';
import '../../services/notification_service.dart';
import '../../utils/distance_formatter.dart';
import 'car_proximity_state.dart';

/// Manages car proximity tracking and arrival notifications.
///
/// Ensures arrival dialogs trigger when in-app and arrival notifications trigger
/// when outside the app, only after the user has left the car area (>= 15m)
/// and then returned to within threshold (<= 5m or <= 1m).
class CarProximityCubit extends Cubit<CarProximityState> {
  CarProximityCubit({
    NotificationService? notificationService,
  })  : notificationService = notificationService ?? const NotificationService(),
        super(const CarProximityState()) {
    try {
      _lifecycleListener = AppLifecycleListener(
        onResume: _handleResume,
        onPause: _handlePause,
        onHide: _handlePause,
        onDetach: _handlePause,
      );
    } catch (_) {
      // Binding not initialized (e.g. pure unit tests)
    }
  }

  final NotificationService notificationService;
  AppLifecycleListener? _lifecycleListener;
  bool _isForeground = true;

  static const double awayThresholdMeters = 15.0;

  bool get isForeground => _isForeground;

  /// Visible for testing or manual lifecycle changes.
  void setForeground(bool isForeground) {
    _isForeground = isForeground;
  }

  void _handleResume() {
    _isForeground = true;
    notificationService.cancelArrivalNotification();
    if (state.hasMovedAway &&
        state.distanceToCar != null &&
        state.distanceToCar! <= state.targetThresholdMeters &&
        !state.isDialogVisible) {
      emit(state.copyWith(shouldShowDialog: true));
    }
  }

  void _handlePause() {
    _isForeground = false;
  }

  void checkProximity({
    required Spot? car,
    required double? userLatitude,
    required double? userLongitude,
    String? arrivalTitle,
    String? arrivalBody,
    String? onMapActionText,
    String? foundCarActionText,
  }) {
    if (car == null) {
      if (state.hasMovedAway ||
          state.shouldShowDialog ||
          state.isDialogVisible ||
          state.hasShownArrivalNotification ||
          state.lastCarSavedAt != null) {
        notificationService.cancelArrivalNotification();
        emit(const CarProximityState());
      }
      return;
    }

    // Detect new parking session
    final isNewParking = state.lastCarSavedAt == null ||
        car.savedAt.isAfter(state.lastCarSavedAt!);
    if (isNewParking) {
      notificationService.cancelArrivalNotification();
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
      if (distance <= state.targetThresholdMeters) {
        if (_isForeground) {
          // Inside app: show dialog only, no notification needed
          notificationService.cancelArrivalNotification();
          if (!state.isDialogVisible && !state.shouldShowDialog) {
            emit(state.copyWith(
              shouldShowDialog: true,
              distanceToCar: () => distance,
            ));
          } else {
            emit(state.copyWith(distanceToCar: () => distance));
          }
        } else {
          // Outside app (background): show push notification with 2 actions
          if (!state.hasShownArrivalNotification) {
            notificationService.showCarArrivalNotification(
              title: arrivalTitle ?? "You're in front of your car!",
              body: arrivalBody ?? 'Open on map or mark as found',
              onMapActionLabel: onMapActionText ?? 'On map',
              foundCarActionLabel: foundCarActionText ?? 'Found my car',
            );
            emit(state.copyWith(
              hasShownArrivalNotification: true,
              distanceToCar: () => distance,
            ));
          } else {
            emit(state.copyWith(distanceToCar: () => distance));
          }
        }
      } else {
        // Distance > target threshold
        if (state.hasShownArrivalNotification) {
          notificationService.cancelArrivalNotification();
          emit(state.copyWith(
            hasShownArrivalNotification: false,
            distanceToCar: () => distance,
          ));
        } else {
          emit(state.copyWith(distanceToCar: () => distance));
        }
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
    notificationService.cancelArrivalNotification();
    emit(const CarProximityState());
  }

  void onDialogDismissed() {
    emit(state.copyWith(isDialogVisible: false, shouldShowDialog: false));
  }

  @override
  Future<void> close() {
    _lifecycleListener?.dispose();
    return super.close();
  }
}
