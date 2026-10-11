import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/car_tracking_state.dart';
import '../utils/car_tracking_calculator.dart';

/// Interface for controlling and listening to live car walking tracking sessions.
abstract interface class CarTrackingService {
  Future<bool> start({
    required double carLat,
    required double carLng,
    required String spotId,
    required DateTime savedAt,
    String? carName,
    bool isArabic = false,
  });

  Future<void> stop();

  Future<bool> isRunning();

  Stream<CarTrackingState> get stateStream;
}

/// Production implementation of [CarTrackingService] backed by platform channels.
class PlatformCarTrackingService implements CarTrackingService {
  PlatformCarTrackingService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel('feen/car_tracking'),
        _eventChannel =
            eventChannel ?? const EventChannel('feen/car_tracking/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<CarTrackingState>? _cachedStream;

  @override
  Future<bool> start({
    required double carLat,
    required double carLng,
    required String spotId,
    required DateTime savedAt,
    String? carName,
    bool isArabic = false,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('start', {
        'carLat': carLat,
        'carLng': carLng,
        'spotId': spotId,
        'carSavedAt': savedAt.millisecondsSinceEpoch,
        'carName': carName ?? 'My car',
        'isArabic': isArabic,
      });
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint('PlatformCarTrackingService.start error: $e');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod<void>('stop');
    } on PlatformException catch (e) {
      debugPrint('PlatformCarTrackingService.stop error: $e');
    }
  }

  @override
  Future<bool> isRunning() async {
    try {
      final running = await _methodChannel.invokeMethod<bool>('isRunning');
      return running ?? false;
    } on PlatformException catch (e) {
      debugPrint('PlatformCarTrackingService.isRunning error: $e');
      return false;
    }
  }

  @override
  Stream<CarTrackingState> get stateStream {
    _cachedStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(_parseEvent)
        .handleError((error) {
      debugPrint('CarTrackingService event stream error: $error');
      return CarTrackingState(
        status: CarTrackingStatus.idle,
        errorMessage: error.toString(),
      );
    });
    return _cachedStream!;
  }

  CarTrackingState _parseEvent(dynamic raw) {
    if (raw is! Map) {
      return const CarTrackingState();
    }

    final map = Map<String, dynamic>.from(raw);
    final stateString = map['state'] as String? ?? 'idle';

    CarTrackingStatus status;
    switch (stateString) {
      case 'waitingForGps':
        status = CarTrackingStatus.waitingForGps;
        break;
      case 'walking':
        status = CarTrackingStatus.walking;
        break;
      case 'arrived':
        status = CarTrackingStatus.arrived;
        break;
      case 'stopped':
      case 'foundCar':
        status = CarTrackingStatus.stopped;
        break;
      default:
        status = CarTrackingStatus.idle;
    }

    final distanceMeters = (map['distanceMeters'] as num?)?.toDouble();
    final walkMinutes = (map['walkMinutes'] as num?)?.toInt();
    final progress = (map['progress'] as num?)?.toDouble() ?? 0.0;
    final isArabic = map['isArabic'] as bool? ?? false;
    final isArrived = map['isArrived'] as bool? ?? (status == CarTrackingStatus.arrived);

    final formattedDist = distanceMeters != null
        ? CarTrackingCalculator.formatDistance(distanceMeters, isArabic: isArabic)
        : '';
    final formattedWalk = walkMinutes != null
        ? CarTrackingCalculator.formatWalkTime(walkMinutes, isArabic: isArabic)
        : '';

    return CarTrackingState(
      status: status,
      distanceMeters: distanceMeters,
      walkMinutes: walkMinutes,
      progress: progress.clamp(0.0, 1.0),
      formattedDistance: formattedDist,
      formattedWalkTime: formattedWalk,
      isArrived: isArrived,
    );
  }
}
