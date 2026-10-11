import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/car_tracking/car_tracking_cubit.dart';
import 'package:feen/shared/models/car_tracking_state.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/services/car_tracking_service.dart';
import 'package:feen/shared/utils/car_tracking_calculator.dart';

void main() {
  group('CarTrackingCalculator - Distance Calculation & Formatting', () {
    test('calculateDistance computes accurate geodesic distance', () {
      // Cairo to Alexandria approx 180 km
      final distance = CarTrackingCalculator.calculateDistance(
        startLatitude: 30.0444,
        startLongitude: 31.2357,
        endLatitude: 31.2001,
        endLongitude: 29.9187,
      );
      expect((distance / 1000).round(), closeTo(180, 5));
    });

    test('formatDistance rounds < 100 m to nearest 5 m', () {
      expect(CarTrackingCalculator.formatDistance(0), '0 m');
      expect(CarTrackingCalculator.formatDistance(4), '5 m');
      expect(CarTrackingCalculator.formatDistance(7), '5 m');
      expect(CarTrackingCalculator.formatDistance(12), '10 m');
      expect(CarTrackingCalculator.formatDistance(13), '15 m');
      expect(CarTrackingCalculator.formatDistance(98), '100 m');
    });

    test('formatDistance rounds 100 to 999 m to nearest 10 m', () {
      expect(CarTrackingCalculator.formatDistance(100), '100 m');
      expect(CarTrackingCalculator.formatDistance(244), '240 m');
      expect(CarTrackingCalculator.formatDistance(246), '250 m');
      expect(CarTrackingCalculator.formatDistance(994), '990 m');
      expect(CarTrackingCalculator.formatDistance(996), '1.0 km');
    });

    test('formatDistance shows one decimal for >= 1 km', () {
      expect(CarTrackingCalculator.formatDistance(1000), '1.0 km');
      expect(CarTrackingCalculator.formatDistance(1240), '1.2 km');
      expect(CarTrackingCalculator.formatDistance(5432), '5.4 km');
    });

    test('formatDistance supports Arabic units', () {
      expect(CarTrackingCalculator.formatDistance(15, isArabic: true), '15 م');
      expect(CarTrackingCalculator.formatDistance(240, isArabic: true), '240 م');
      expect(CarTrackingCalculator.formatDistance(1200, isArabic: true), '1.2 كم');
    });
  });

  group('CarTrackingCalculator - Walk Time', () {
    test('calculateWalkMinutes calculates correct minutes based on 1.4 m/s', () {
      // 70 m: 70 / 1.4 = 50 seconds -> under 1 minute -> 0
      expect(CarTrackingCalculator.calculateWalkMinutes(70), 0);

      // 84 m: 84 / 1.4 = 60 seconds -> 1 min
      expect(CarTrackingCalculator.calculateWalkMinutes(84), 1);

      // 240 m: 240 / 1.4 = 171.4 s -> 2.85 min -> ceil 3 min
      expect(CarTrackingCalculator.calculateWalkMinutes(240), 3);
    });

    test('formatWalkTime formats in English and Arabic', () {
      expect(CarTrackingCalculator.formatWalkTime(0), 'Less than a minute');
      expect(CarTrackingCalculator.formatWalkTime(0, isArabic: true), 'أقل من دقيقة');

      expect(CarTrackingCalculator.formatWalkTime(1), 'About 1 min walk');
      expect(CarTrackingCalculator.formatWalkTime(1, isArabic: true), 'حوالي دقيقة سيرًا');

      expect(CarTrackingCalculator.formatWalkTime(2, isArabic: true), 'حوالي دقيقتين سيرًا');
      expect(CarTrackingCalculator.formatWalkTime(3, isArabic: true), 'حوالي 3 دقائق سيرًا');
      expect(CarTrackingCalculator.formatWalkTime(15, isArabic: true), 'حوالي 15 دقيقة سيرًا');

      expect(CarTrackingCalculator.formatWalkTime(3), 'About 3 min walk');
    });
  });

  group('CarTrackingCalculator - Progress & 1.5x Reset', () {
    test('calculateProgress clamps between 0.0 and 1.0', () {
      // startDistance = 200, current = 200 -> 0.0
      expect(CarTrackingCalculator.calculateProgress(currentDistance: 200, startDistance: 200), 0.0);

      // startDistance = 200, current = 100 -> 0.5
      expect(CarTrackingCalculator.calculateProgress(currentDistance: 100, startDistance: 200), 0.5);

      // startDistance = 200, current = 0 -> 1.0
      expect(CarTrackingCalculator.calculateProgress(currentDistance: 0, startDistance: 200), 1.0);

      // current > startDistance -> 0.0
      expect(CarTrackingCalculator.calculateProgress(currentDistance: 250, startDistance: 200), 0.0);

      // current < 0 -> 1.0
      expect(CarTrackingCalculator.calculateProgress(currentDistance: -10, startDistance: 200), 1.0);
    });

    test('shouldResetStartDistance detects user moving beyond 1.5x startDistance', () {
      expect(
        CarTrackingCalculator.shouldResetStartDistance(currentDistance: 250, startDistance: 200),
        false,
      );
      expect(
        CarTrackingCalculator.shouldResetStartDistance(currentDistance: 300, startDistance: 200),
        false,
      );
      expect(
        CarTrackingCalculator.shouldResetStartDistance(currentDistance: 301, startDistance: 200),
        true,
      );
    });
  });

  group('CarTrackingCalculator - Arrival Hysteresis', () {
    test('enters arrived when distance <= 15 m and accuracy <= 25 m', () {
      expect(
        CarTrackingCalculator.checkArrival(
          distance: 14.0,
          horizontalAccuracy: 10.0,
          currentlyArrived: false,
        ),
        true,
      );

      // Low accuracy (> 25m) does not enter arrived
      expect(
        CarTrackingCalculator.checkArrival(
          distance: 14.0,
          horizontalAccuracy: 26.0,
          currentlyArrived: false,
        ),
        false,
      );

      // Distance > 15m does not enter arrived
      expect(
        CarTrackingCalculator.checkArrival(
          distance: 16.0,
          horizontalAccuracy: 5.0,
          currentlyArrived: false,
        ),
        false,
      );
    });

    test('stays arrived until distance > 30 m', () {
      expect(
        CarTrackingCalculator.checkArrival(
          distance: 25.0,
          horizontalAccuracy: 50.0,
          currentlyArrived: true,
        ),
        true,
      );

      expect(
        CarTrackingCalculator.checkArrival(
          distance: 30.0,
          horizontalAccuracy: 10.0,
          currentlyArrived: true,
        ),
        true,
      );

      expect(
        CarTrackingCalculator.checkArrival(
          distance: 31.0,
          horizontalAccuracy: 10.0,
          currentlyArrived: true,
        ),
        false,
      );
    });
  });

  group('CarTrackingCalculator - Max Distance', () {
    test('isTooFar flags distances > 50 km', () {
      expect(CarTrackingCalculator.isTooFar(49999), false);
      expect(CarTrackingCalculator.isTooFar(50000), false);
      expect(CarTrackingCalculator.isTooFar(50001), true);
    });
  });

  group('CarTrackingState model', () {
    test('copyWith and equality work properly', () {
      const state1 = CarTrackingState(
        status: CarTrackingStatus.walking,
        distanceMeters: 240,
        walkMinutes: 3,
        progress: 0.25,
      );

      final state2 = state1.copyWith(progress: 0.5);
      expect(state2.progress, 0.5);
      expect(state2.distanceMeters, 240);
      expect(state2.isRunning, true);

      final state3 = const CarTrackingState().copyWith(status: CarTrackingStatus.idle);
      expect(state3.isRunning, false);
    });
  });

  group('CarTrackingCubit', () {
    test('startCarTracking rejects if distance > 50 km', () async {
      final fakeService = _FakeCarTrackingService();
      final cubit = CarTrackingCubit(carTrackingService: fakeService);

      final car = Spot(
        id: 'car',
        name: 'Car',
        category: SpotCategory.car,
        latitude: 31.0,
        longitude: 31.0,
        savedAt: DateTime.now(),
      );

      // 100 km away
      final started = await cubit.startCarTracking(
        car: car,
        currentLat: 30.0,
        currentLng: 31.0,
      );

      expect(started, false);
      expect(cubit.state.errorMessage, 'tooFar');
      expect(cubit.state.status, CarTrackingStatus.idle);

      await cubit.close();
    });

    test('startCarTracking starts service and updates state', () async {
      final fakeService = _FakeCarTrackingService();
      final cubit = CarTrackingCubit(carTrackingService: fakeService);

      final car = Spot(
        id: 'car',
        name: 'Car',
        category: SpotCategory.car,
        latitude: 30.044,
        longitude: 31.235,
        savedAt: DateTime.now(),
      );

      final started = await cubit.startCarTracking(
        car: car,
        currentLat: 30.045,
        currentLng: 31.236,
      );

      expect(started, true);
      expect(cubit.state.status, CarTrackingStatus.walking);
      expect(cubit.state.distanceMeters, isNotNull);

      // Emit walking update from service
      fakeService.emitState(
        const CarTrackingState(
          status: CarTrackingStatus.walking,
          distanceMeters: 140,
          walkMinutes: 2,
          progress: 0.3,
        ),
      );

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, CarTrackingStatus.walking);
      expect(cubit.state.distanceMeters, 140);
      expect(cubit.state.walkMinutes, 2);

      await cubit.stopCarTracking();
      expect(cubit.state.status, CarTrackingStatus.idle);

      await cubit.close();
    });

    test('startCarTracking emits waitingForGps when user coordinates are null', () async {
      final fakeService = _FakeCarTrackingService();
      final cubit = CarTrackingCubit(carTrackingService: fakeService);

      final car = Spot(
        id: 'car',
        name: 'Car',
        category: SpotCategory.car,
        latitude: 30.044,
        longitude: 31.235,
        savedAt: DateTime.now(),
      );

      final started = await cubit.startCarTracking(car: car);

      expect(started, true);
      expect(cubit.state.status, CarTrackingStatus.waitingForGps);

      await cubit.close();
    });
  });
}

class _FakeCarTrackingService implements CarTrackingService {
  final _controller = StreamController<CarTrackingState>.broadcast();
  bool _running = false;

  void emitState(CarTrackingState state) => _controller.add(state);

  @override
  Stream<CarTrackingState> get stateStream => _controller.stream;

  @override
  Future<bool> isRunning() async => _running;

  @override
  Future<bool> start({
    required double carLat,
    required double carLng,
    required String spotId,
    required DateTime savedAt,
    String? carName,
    bool isArabic = false,
    double? userLat,
    double? userLng,
  }) async {
    _running = true;
    return true;
  }

  @override
  Future<void> stop() async {
    _running = false;
    _controller.add(const CarTrackingState(status: CarTrackingStatus.stopped));
  }
}
