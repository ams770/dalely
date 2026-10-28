import 'package:flutter/foundation.dart';

/// Status of the active car walking tracking session.
enum CarTrackingStatus {
  idle,
  waitingForGps,
  walking,
  arrived,
  stopped,
}

/// Immutable state representing active walking navigation to the parked car.
@immutable
class CarTrackingState {
  const CarTrackingState({
    this.status = CarTrackingStatus.idle,
    this.distanceMeters,
    this.walkMinutes,
    this.progress = 0.0,
    this.formattedDistance = '',
    this.formattedWalkTime = '',
    this.startDistanceMeters,
    this.isArrived = false,
    this.errorMessage,
  });

  final CarTrackingStatus status;
  final double? distanceMeters;
  final int? walkMinutes;
  final double progress;
  final String formattedDistance;
  final String formattedWalkTime;
  final double? startDistanceMeters;
  final bool isArrived;
  final String? errorMessage;

  bool get isRunning =>
      status == CarTrackingStatus.waitingForGps ||
      status == CarTrackingStatus.walking ||
      status == CarTrackingStatus.arrived;

  CarTrackingState copyWith({
    CarTrackingStatus? status,
    ValueGetter<double?>? distanceMeters,
    ValueGetter<int?>? walkMinutes,
    double? progress,
    String? formattedDistance,
    String? formattedWalkTime,
    ValueGetter<double?>? startDistanceMeters,
    bool? isArrived,
    ValueGetter<String?>? errorMessage,
  }) {
    return CarTrackingState(
      status: status ?? this.status,
      distanceMeters:
          distanceMeters != null ? distanceMeters() : this.distanceMeters,
      walkMinutes: walkMinutes != null ? walkMinutes() : this.walkMinutes,
      progress: progress ?? this.progress,
      formattedDistance: formattedDistance ?? this.formattedDistance,
      formattedWalkTime: formattedWalkTime ?? this.formattedWalkTime,
      startDistanceMeters: startDistanceMeters != null
          ? startDistanceMeters()
          : this.startDistanceMeters,
      isArrived: isArrived ?? this.isArrived,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarTrackingState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          distanceMeters == other.distanceMeters &&
          walkMinutes == other.walkMinutes &&
          (progress - other.progress).abs() < 0.0001 &&
          formattedDistance == other.formattedDistance &&
          formattedWalkTime == other.formattedWalkTime &&
          startDistanceMeters == other.startDistanceMeters &&
          isArrived == other.isArrived &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        distanceMeters,
        walkMinutes,
        progress.toStringAsFixed(3),
        formattedDistance,
        formattedWalkTime,
        startDistanceMeters,
        isArrived,
        errorMessage,
      );
}
