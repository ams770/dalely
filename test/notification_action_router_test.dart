import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feen/app/app_router.dart';
import 'package:feen/app/notification_action_router.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/car_proximity/car_proximity_cubit.dart';
import 'package:feen/shared/cubits/car_proximity/car_proximity_state.dart';
import 'package:feen/shared/cubits/car_tracking/car_tracking_cubit.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/cubits/location/location_state.dart';
import 'package:feen/shared/cubits/spots/spots_cubit.dart';
import 'package:feen/shared/cubits/spots/spots_state.dart';
import 'package:feen/shared/models/car_tracking_state.dart';
import 'package:feen/shared/models/spot.dart';

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit({Spot? initialCar})
      : clearCarCallCount = 0,
        super(SpotsState(car: initialCar));

  int clearCarCallCount;

  @override
  Future<void> clearCar() async {
    clearCarCallCount++;
    emit(state.copyWith(clearCar: true));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCarTrackingCubit extends Cubit<CarTrackingState>
    implements CarTrackingCubit {
  _FakeCarTrackingCubit()
      : stopCallCount = 0,
        super(const CarTrackingState());

  int stopCallCount;

  @override
  Future<void> stopCarTracking() async {
    stopCallCount++;
    emit(const CarTrackingState(status: CarTrackingStatus.stopped));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCarProximityCubit extends Cubit<CarProximityState>
    implements CarProximityCubit {
  _FakeCarProximityCubit()
      : onFoundCarCallCount = 0,
        super(const CarProximityState());

  int onFoundCarCallCount;

  @override
  void onFoundCar() {
    onFoundCarCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit() : super(const LocationState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GlobalKey<NavigatorState> navKey;
  late _FakeSpotsCubit fakeSpotsCubit;
  late _FakeCarTrackingCubit fakeTrackingCubit;
  late _FakeCarProximityCubit fakeProximityCubit;
  late _FakeLocationCubit fakeLocationCubit;

  setUp(() {
    navKey = GlobalKey<NavigatorState>();
    fakeSpotsCubit = _FakeSpotsCubit(
      initialCar: Spot(
        id: 'car',
        name: 'My Car',
        category: SpotCategory.car,
        latitude: 30.0,
        longitude: 31.0,
        savedAt: DateTime.now(),
      ),
    );
    fakeTrackingCubit = _FakeCarTrackingCubit();
    fakeProximityCubit = _FakeCarProximityCubit();
    fakeLocationCubit = _FakeLocationCubit();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('feen/notification_actions'),
      (call) async {
        if (call.method == 'clearPendingAction') return true;
        if (call.method == 'getInitialAction') return null;
        if (call.method == 'getPendingAction') return null;
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('feen/notification_actions'),
      null,
    );
  });

  Widget buildTestApp(NotificationActionRouter router) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SpotsCubit>.value(value: fakeSpotsCubit),
        BlocProvider<CarTrackingCubit>.value(value: fakeTrackingCubit),
        BlocProvider<CarProximityCubit>.value(value: fakeProximityCubit),
        BlocProvider<LocationCubit>.value(value: fakeLocationCubit),
      ],
      child: MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: Text('Home')),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: Text('Page: ${settings.name}')),
            settings: settings,
          );
        },
      ),
    );
  }

  group('NotificationActionRouter Unit & Widget Tests', () {
    testWidgets('De-duplication: rapid repeat action within 1500ms executes only once',
        (tester) async {
      final router = NotificationActionRouter(
        navigatorKey: navKey,
      );

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      final now = DateTime.now().millisecondsSinceEpoch;

      // First call
      await router.handleAction(action: 'FOUND_CAR', timestamp: now);
      // Second call immediately with same timestamp
      await router.handleAction(action: 'FOUND_CAR', timestamp: now + 50);

      expect(fakeSpotsCubit.clearCarCallCount, 1);
      expect(fakeTrackingCubit.stopCallCount, 1);
      expect(fakeProximityCubit.onFoundCarCallCount, 1);
    });

    testWidgets('Idempotent FOUND_CAR clears car, stops tracking, and updates state',
        (tester) async {
      final router = NotificationActionRouter(
        navigatorKey: navKey,
      );

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      await router.handleAction(action: 'FOUND_CAR');

      expect(fakeSpotsCubit.clearCarCallCount, 1);
      expect(fakeTrackingCubit.stopCallCount, 1);
      expect(fakeProximityCubit.onFoundCarCallCount, 1);
      expect(fakeSpotsCubit.state.car, isNull);
    });

    testWidgets('SHOW_MAP skips navigation if current route is already on top',
        (tester) async {
      var currentRoute = AppRouter.spotsMap;
      final router = NotificationActionRouter(
        navigatorKey: navKey,
        currentRouteGetter: () => currentRoute,
      );

      await tester.pumpWidget(buildTestApp(router));
      await tester.pumpAndSettle();

      // Current route is already spotsMap
      await router.handleAction(action: 'SHOW_MAP');
      await tester.pumpAndSettle();

      // Should not have pushed a new route
      expect(find.text('Page: ${AppRouter.spotsMap}'), findsNothing);
    });

    testWidgets('Readiness waiting: retries until context is mounted',
        (tester) async {
      final router = NotificationActionRouter(
        navigatorKey: navKey,
      );

      await tester.runAsync(() async {
        // Trigger action while unmounted
        final future = router.handleAction(action: 'FOUND_CAR');
        // Give a tiny delay for attempt 0 to fail and trigger wait
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Mount the app
        await tester.pumpWidget(buildTestApp(router));
        // Await the queued action to complete after finding context
        await future;
      });

      expect(fakeSpotsCubit.clearCarCallCount, 1);
      expect(fakeTrackingCubit.stopCallCount, 1);
    });
  });
}
