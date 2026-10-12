import 'package:feen/app/app_router.dart';
import 'package:feen/app/notification_action_router.dart';
import 'package:feen/modules/spots_map/cubit/spots_map_cubit.dart';
import 'package:feen/modules/spots_map/cubit/spots_map_state.dart';
import 'package:feen/modules/spots_map/spots_map_screen.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/cubits/location/location_state.dart';
import 'package:feen/shared/cubits/spots/spots_cubit.dart';
import 'package:feen/shared/cubits/spots/spots_state.dart';
import 'package:feen/shared/services/marker_icon_cache.dart';
import 'package:feen/shared/theme/app_theme_extension.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';
import 'package:feen/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit() : super(const SpotsState());
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

  group('Location Intent Routing - AppRouter', () {
    testWidgets('saveSpot route parses SaveSpotArgs and creates SpotsMapScreen',
        (tester) async {
      const target = LatLng(30.0444, 31.2357);
      const args = SaveSpotArgs(target: target, name: 'Downtown Pharmacy');

      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRouter.saveSpot, arguments: args),
      );

      expect(route, isA<MaterialPageRoute>());
      final pageRoute = route as MaterialPageRoute;

      late Widget builtWidget;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              builtWidget = pageRoute.builder(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(builtWidget, isA<SpotsMapScreen>());
      final mapScreen = builtWidget as SpotsMapScreen;
      expect(mapScreen.initialMode, SpotsMapMode.addSpot);
      expect(mapScreen.initialTarget, target);
      expect(mapScreen.initialSpotName, 'Downtown Pharmacy');
    });
  });

  group('Location Intent Routing - SpotsMapCubit', () {
    test('initializes with initialTarget and initialSpotName pre-filled', () {
      const target = LatLng(24.7136, 46.6753);
      final cubit = SpotsMapCubit(
        spotsCubit: _FakeSpotsCubit(),
        locationCubit: _FakeLocationCubit(),
        markerIconCache: MarkerIconCache(),
        themeExtension: AppThemeExtension.light,
        initialTarget: target,
        initialSpotName: 'Riyadh Mall',
        initialMode: SpotsMapMode.addSpot,
      );

      expect(cubit.state.mode, SpotsMapMode.addSpot);
      expect(cubit.state.pickedLocation, target);
      expect(cubit.state.initialTarget, target);
      expect(cubit.state.spotName, 'Riyadh Mall');
      expect(cubit.nameController.text, 'Riyadh Mall');

      cubit.close();
    });
  });

  group('Location Intent Routing - NotificationActionRouter', () {
    testWidgets('OPEN_LOCATION action navigates to saveSpot with parsed coordinates',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      final router = NotificationActionRouter(navigatorKey: navKey);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: _FakeSpotsCubit()),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            navigatorKey: navKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger location action with geo URI containing coordinates and label
      await router.handleAction(
        action: 'OPEN_LOCATION',
        data: 'geo:0,0?q=30.0444,31.2357(Central Market)',
      );
      await tester.pumpAndSettle();

      // Verify SpotsMapScreen is pushed in addSpot mode
      expect(find.byType(SpotsMapScreen), findsOneWidget);
      final mapScreen = tester.widget<SpotsMapScreen>(find.byType(SpotsMapScreen));
      expect(mapScreen.initialMode, SpotsMapMode.addSpot);
      expect(mapScreen.initialTarget?.latitude, 30.0444);
      expect(mapScreen.initialTarget?.longitude, 31.2357);
      expect(mapScreen.initialSpotName, 'Central Market');
    });

    testWidgets('handleUri handles geo: and feen://save URIs', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      final router = NotificationActionRouter(navigatorKey: navKey);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: _FakeSpotsCubit()),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            navigatorKey: navKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.handleUri(Uri.parse('geo:25.2048,55.2708'));
      await tester.pumpAndSettle();

      expect(find.byType(SpotsMapScreen), findsOneWidget);
      final mapScreen = tester.widget<SpotsMapScreen>(find.byType(SpotsMapScreen));
      expect(mapScreen.initialTarget?.latitude, 25.2048);
      expect(mapScreen.initialTarget?.longitude, 55.2708);
    });

    testWidgets('OPEN_LOCATION action with text-only payload pre-fills name and opens saveSpot',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      final router = NotificationActionRouter(navigatorKey: navKey);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: _FakeSpotsCubit()),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            navigatorKey: navKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await router.handleAction(
        action: 'OPEN_LOCATION',
        data: 'Cairo Festival City Mall\nhttps://example.com/offline',
      );
      await tester.pumpAndSettle();

      expect(find.byType(SpotsMapScreen), findsOneWidget);
      final mapScreen =
          tester.widget<SpotsMapScreen>(find.byType(SpotsMapScreen));
      expect(mapScreen.initialMode, SpotsMapMode.addSpot);
      expect(mapScreen.initialSpotName, 'Cairo Festival City Mall');
    });
  });
}
