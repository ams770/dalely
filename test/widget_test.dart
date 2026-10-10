import 'package:feen/shared/constants/app_assets.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/car_proximity/car_proximity_cubit.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/utils/distance_formatter.dart';
import 'package:feen/shared/utils/spot_link_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    test('resets proximity state when car is found', () {
      final cubit = CarProximityCubit();
      cubit.onFoundCar();
      expect(cubit.state.hasMovedAway, isFalse);
      expect(cubit.state.targetThresholdMeters, 5.0);
      expect(cubit.state.shouldShowDialog, isFalse);
    });
  });

  group('AssetProvider', () {
    test('contains correct car image asset path', () {
      expect(AssetProvider.car, 'assets/images/car.png');
      expect(AssetProvider.carImage.assetName, 'assets/images/car.png');
    });
  });
}
