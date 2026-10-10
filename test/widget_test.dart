import 'package:feen/modules/home/cubit/parking_timer_cubit.dart';
import 'package:feen/modules/save_spot/cubit/save_spot_state.dart';
import 'package:feen/shared/constants/app_assets.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/car_proximity/car_proximity_cubit.dart';
import 'package:feen/shared/models/app_settings.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/utils/distance_formatter.dart';
import 'package:feen/shared/utils/duration_formatter.dart';
import 'package:feen/shared/utils/spot_link_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DistanceFormatter', () {
    test('calculates distance accurately between two coordinates', () {
      // Cairo Tower to Tahrir Square (~1.3 km)
      final distance = DistanceFormatter.calculateDistance(
        startLatitude: 30.0459,
        startLongitude: 31.2243,
        endLatitude: 30.0444,
        endLongitude: 31.2357,
      );

      expect(distance, greaterThan(1000));
      expect(distance, lessThan(1600));
    });

    test('formatShort formats meters and kilometers cleanly', () {
      expect(DistanceFormatter.formatShort(250), '250 m');
      expect(DistanceFormatter.formatShort(1540), '1.5 km');
      expect(DistanceFormatter.formatShort(12500), '13 km');
    });
  });

  group('SpotLinkBuilder', () {
    test('builds correct map URL', () {
      final url = SpotLinkBuilder.mapUrl(
        latitude: 30.0444,
        longitude: 31.2357,
      );
      expect(url, 'https://maps.google.com/?q=30.0444,31.2357');
    });
  });

  group('Spot Model', () {
    test('isCar property works correctly', () {
      final carSpot = Spot(
        id: 'car',
        name: '',
        category: SpotCategory.car,
        latitude: 30.0,
        longitude: 31.0,
        savedAt: DateTime(2026, 10, 10),
      );

      final homeSpot = Spot(
        id: '123',
        name: 'Home',
        category: SpotCategory.home,
        latitude: 30.0,
        longitude: 31.0,
        savedAt: DateTime(2026, 10, 10),
      );

      expect(carSpot.isCar, isTrue);
      expect(homeSpot.isCar, isFalse);
    });
  });

  group('CarProximityCubit', () {
    test('does not trigger dialog immediately after parking (distance 0m)', () {
      final cubit = CarProximityCubit();
      final now = DateTime.now();
      final car = Spot(
        id: 'car',
        name: '',
        category: SpotCategory.car,
        latitude: 30.0459,
        longitude: 31.2243,
        savedAt: now,
      );

      // User is at the same location as car right after parking
      cubit.checkProximity(
        car: car,
        userLatitude: 30.0459,
        userLongitude: 31.2243,
      );

      expect(cubit.state.hasMovedAway, isFalse);
      expect(cubit.state.shouldShowDialog, isFalse);
    });

    test('triggers dialog after moving >= 15m away and returning within 5m', () {
      final cubit = CarProximityCubit();
      final now = DateTime.now();
      final car = Spot(
        id: 'car',
        name: '',
        category: SpotCategory.car,
        latitude: 30.0459,
        longitude: 31.2243,
        savedAt: now,
      );

      // User is initially at car
      cubit.checkProximity(
        car: car,
        userLatitude: 30.0459,
        userLongitude: 31.2243,
      );
      expect(cubit.state.hasMovedAway, isFalse);

      // User moves ~100m away
      cubit.checkProximity(
        car: car,
        userLatitude: 30.0468,
        userLongitude: 31.2243,
      );
      expect(cubit.state.hasMovedAway, isTrue);
      expect(cubit.state.shouldShowDialog, isFalse);

      // User walks back to within 4m of car
      cubit.checkProximity(
        car: car,
        userLatitude: 30.045903,
        userLongitude: 31.224303,
      );
      expect(cubit.state.shouldShowDialog, isTrue);
    });

    test('updates threshold to 1m when user cannot see car', () {
      final cubit = CarProximityCubit();
      cubit.onCantSeeCar();
      expect(cubit.state.targetThresholdMeters, 1.0);
      expect(cubit.state.shouldShowDialog, isFalse);
    });

    test('shows notification and no dialog when user returns to car while in background', () {
      final cubit = CarProximityCubit();
      final now = DateTime.now();
      final car = Spot(
        id: 'car',
        name: '',
        category: SpotCategory.car,
        latitude: 30.0459,
        longitude: 31.2243,
        savedAt: now,
      );

      cubit.checkProximity(car: car, userLatitude: 30.0459, userLongitude: 31.2243);
      // Move 100m away
      cubit.checkProximity(car: car, userLatitude: 30.0468, userLongitude: 31.2243);
      expect(cubit.state.hasMovedAway, isTrue);

      // App goes to background
      cubit.setForeground(false);

      // User walks back within 4m
      cubit.checkProximity(car: car, userLatitude: 30.045903, userLongitude: 31.224303);
      expect(cubit.state.hasShownArrivalNotification, isTrue);
      expect(cubit.state.shouldShowDialog, isFalse);
    });

    test('resets proximity state when car is found', () {
      final cubit = CarProximityCubit();
      cubit.onFoundCar();
      expect(cubit.state.hasMovedAway, isFalse);
      expect(cubit.state.targetThresholdMeters, 5.0);
      expect(cubit.state.shouldShowDialog, isFalse);
      expect(cubit.state.hasShownArrivalNotification, isFalse);
    });
  });

  group('AssetProvider', () {
    test('contains correct car and onboarding image asset paths', () {
      expect(AssetProvider.car, 'assets/images/car.png');
      expect(AssetProvider.carImage.assetName, 'assets/images/car.png');
      expect(AssetProvider.onboarding1, 'assets/images/onboarding_1.png');
      expect(AssetProvider.onboarding2, 'assets/images/onboarding_2.png');
      expect(AssetProvider.onboarding3, 'assets/images/onboarding_3.png');
    });
  });

  group('AppSettings', () {
    test('defaults hasCompletedOnboarding to false', () {
      const settings = AppSettings();
      expect(settings.hasCompletedOnboarding, isFalse);
    });

    test('copyWith updates hasCompletedOnboarding correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(hasCompletedOnboarding: true);
      expect(updated.hasCompletedOnboarding, isTrue);
    });
  });

  group('DurationFormatter', () {
    test('formats seconds, minutes, hours, and days correctly', () {
      expect(
        DurationFormatter.formatTimer(const Duration(seconds: 45)),
        '00:00:45',
      );
      expect(
        DurationFormatter.formatTimer(
          const Duration(minutes: 14, seconds: 20),
        ),
        '00:14:20',
      );
      expect(
        DurationFormatter.formatTimer(
          const Duration(hours: 3, minutes: 25, seconds: 10),
        ),
        '03:25:10',
      );
      expect(
        DurationFormatter.formatTimer(
          const Duration(days: 2, hours: 5, minutes: 12, seconds: 0),
        ),
        '2 d 05:12:00',
      );
    });

    test('handles negative duration gracefully', () {
      expect(
        DurationFormatter.formatTimer(const Duration(seconds: -10)),
        '00:00:00',
      );
    });
  });

  group('ParkingTimerCubit', () {
    test('initializes with correct elapsed duration', () {
      final savedAt = DateTime.now().subtract(const Duration(minutes: 5));
      final cubit = ParkingTimerCubit(
        savedAt: savedAt,
        nowProvider: () => const Duration(minutes: 5),
      );

      expect(cubit.state.elapsed.inMinutes, 5);
      expect(cubit.state.formattedElapsed, '00:05:00');
      cubit.close();
    });
  });

  group('SpotCategory', () {
    test('selectable categories start with other (None), restaurant, fuel, gym, mosque', () {
      final selectable = SpotCategory.selectable;
      expect(selectable.first, SpotCategory.other);
      expect(selectable[1], SpotCategory.restaurant);
      expect(selectable[2], SpotCategory.fuel);
      expect(selectable[3], SpotCategory.gym);
      expect(selectable[4], SpotCategory.mosque);
      expect(selectable.contains(SpotCategory.car), isFalse);
    });

    test('SaveSpotState defaults to SpotCategory.other', () {
      const state = SaveSpotState();
      expect(state.category, SpotCategory.other);
    });
  });
}
