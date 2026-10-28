import 'package:flutter/foundation.dart';

class CarProximityState {
  const CarProximityState({
    this.hasMovedAway = false,
    this.targetThresholdMeters = 15.0,
    this.isDialogVisible = false,
    this.shouldShowDialog = false,
    this.hasShownArrivalNotification = false,
    this.lastCarSavedAt,
    this.distanceToCar,
  });

  /// True once the user has moved away (>= 15m) from the parked car.
  /// Prevents the arrival dialog from popping up immediately after parking.
  final bool hasMovedAway;

  /// Current arrival distance trigger (5.0m initially, 1.0m if user couldn't see the car).
  final double targetThresholdMeters;

  /// True when the arrival dialog is actively presented on screen.
  final bool isDialogVisible;

  /// Trigger flag instructing the UI to open the arrival dialog.
  final bool shouldShowDialog;

  /// True when the arrival push notification has been sent while outside the app.
  final bool hasShownArrivalNotification;

  /// Timestamp of the car parking session.
  final DateTime? lastCarSavedAt;

  /// Live distance to the car in meters.
  final double? distanceToCar;

  CarProximityState copyWith({
    bool? hasMovedAway,
    double? targetThresholdMeters,
    bool? isDialogVisible,
    bool? shouldShowDialog,
    bool? hasShownArrivalNotification,
    DateTime? lastCarSavedAt,
    ValueGetter<double?>? distanceToCar,
  }) {
    return CarProximityState(
      hasMovedAway: hasMovedAway ?? this.hasMovedAway,
      targetThresholdMeters:
          targetThresholdMeters ?? this.targetThresholdMeters,
      isDialogVisible: isDialogVisible ?? this.isDialogVisible,
      shouldShowDialog: shouldShowDialog ?? this.shouldShowDialog,
      hasShownArrivalNotification:
          hasShownArrivalNotification ?? this.hasShownArrivalNotification,
      lastCarSavedAt: lastCarSavedAt ?? this.lastCarSavedAt,
      distanceToCar:
          distanceToCar != null ? distanceToCar() : this.distanceToCar,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarProximityState &&
          other.hasMovedAway == hasMovedAway &&
          other.targetThresholdMeters == targetThresholdMeters &&
          other.isDialogVisible == isDialogVisible &&
          other.shouldShowDialog == shouldShowDialog &&
          other.hasShownArrivalNotification == hasShownArrivalNotification &&
          other.lastCarSavedAt == lastCarSavedAt &&
          other.distanceToCar == distanceToCar;

  @override
  int get hashCode => Object.hash(
        hasMovedAway,
        targetThresholdMeters,
        isDialogVisible,
        shouldShowDialog,
        hasShownArrivalNotification,
        lastCarSavedAt,
        distanceToCar,
      );
}
