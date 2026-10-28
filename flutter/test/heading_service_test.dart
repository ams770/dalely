import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/models/location_access.dart';
import 'package:feen/shared/services/heading_service.dart';
import 'package:feen/shared/services/location_service.dart';

class _FakeLocationService implements LocationService {
  _FakeLocationService({this.access = LocationAccess.granted});

  final LocationAccess access;
  final StreamController<Position> positionController =
      StreamController<Position>.broadcast();

  @override
  Future<LocationAccess> checkPermission() async => access;

  @override
  Future<LocationAccess> requestPermission() async => access;

  @override
  Future<Position?> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 6),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async => null;

  @override
  Future<Position?> getLastKnownPosition() async => null;

  @override
  Stream<Position> getPositionStream({int distanceFilter = 5}) =>
      positionController.stream;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HeadingService', () {
    test('emits initial heading and filters delta < minDeltaDegrees', () async {
      final controller = StreamController<double>();
      final service = HeadingService(
        minDeltaDegrees: 3.0,
        customStream: controller.stream,
      );

      final received = <double>[];
      final sub = service.events!.listen(received.add);

      controller.add(10.0); // Initial: emitted
      controller.add(11.0); // Delta 1.0: filtered
      controller.add(12.5); // Delta 2.5: filtered
      controller.add(13.0); // Delta 3.0: emitted
      controller.add(12.0); // Delta 1.0: filtered
      controller.add(20.0); // Delta 7.0: emitted

      await Future<void>.delayed(Duration.zero);
      expect(received, [10.0, 13.0, 20.0]);

      await sub.cancel();
      await controller.close();
    });

    test('handles 360/0 degree wraparound correctly', () async {
      final controller = StreamController<double>();
      final service = HeadingService(
        minDeltaDegrees: 3.0,
        customStream: controller.stream,
      );

      final received = <double>[];
      final sub = service.events!.listen(received.add);

      controller.add(359.0); // Initial
      controller.add(359.5); // Delta 0.5: filtered
      controller.add(1.0); // From 359 to 1 is 2 degrees: filtered
      controller.add(2.0); // From 359 to 2 is 3 degrees: emitted
      controller.add(358.0); // From 2 to 358 is 4 degrees: emitted

      await Future<void>.delayed(Duration.zero);
      expect(received, [359.0, 2.0, 358.0]);

      await sub.cancel();
      await controller.close();
    });
  });

  group('LocationCubit with HeadingService', () {
    test('updates state.heading when HeadingService emits', () async {
      final headingController = StreamController<double>();
      final headingService = HeadingService(
        minDeltaDegrees: 3.0,
        customStream: headingController.stream,
      );
      final locationService = _FakeLocationService(access: LocationAccess.granted);

      final cubit = LocationCubit(
        locationService: locationService,
        headingService: headingService,
      );

      // Wait for cubit initialization
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.heading, 0.0);

      headingController.add(45.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.heading, 45.0);

      headingController.add(90.0);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.heading, 90.0);

      await cubit.close();
      await headingController.close();
      await locationService.positionController.close();
    });
  });
}
