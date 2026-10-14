import 'package:feen/modules/home/home_screen.dart';
import 'package:feen/modules/home/widgets/car_card.dart';
import 'package:feen/modules/home/widgets/home_header.dart';
import 'package:feen/modules/home/widgets/home_map_card.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import 'package:feen/shared/cubits/car_proximity/car_proximity_cubit.dart';
import 'package:feen/shared/cubits/car_proximity/car_proximity_state.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/cubits/location/location_state.dart';
import 'package:feen/shared/cubits/settings/settings_cubit.dart';
import 'package:feen/shared/cubits/settings/settings_state.dart';
import 'package:feen/shared/cubits/spots/spots_cubit.dart';
import 'package:feen/shared/cubits/spots/spots_state.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';
import 'package:feen/shared/models/location_access.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/theme/app_theme.dart';
import 'package:feen/shared/widgets/primary_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit(List<Spot> initialSpots, {Spot? car})
      : super(SpotsState(spots: initialSpots, car: car));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit() : super(const LocationState());

  @override
  Future<LocationAccess> requestPermission() async => LocationAccess.granted;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsCubit extends Cubit<SettingsState> implements SettingsCubit {
  _FakeSettingsCubit() : super(const SettingsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCarProximityCubit extends Cubit<CarProximityState>
    implements CarProximityCubit {
  _FakeCarProximityCubit() : super(const CarProximityState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required SpotsCubit spotsCubit,
    AdaptiveNavCubit? adaptiveNavCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SpotsCubit>.value(value: spotsCubit),
        BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
        BlocProvider<SettingsCubit>.value(value: _FakeSettingsCubit()),
        BlocProvider<AdaptiveNavCubit>.value(
          value: adaptiveNavCubit ?? AdaptiveNavCubit(),
        ),
        BlocProvider<CarProximityCubit>.value(value: _FakeCarProximityCubit()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(body: Text('MapScreen')),
        ),
        home: const HomeScreen(),
      ),
    );
  }

  group('HomeHeader', () {
    testWidgets('does not render old map button in header', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final spotsCubit = _FakeSpotsCubit([]);

      await tester.pumpWidget(buildTestWidget(spotsCubit: spotsCubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // HomeHeader exists
      expect(find.byType(HomeHeader), findsOneWidget);

      // Map button in header is removed
      expect(
        find.descendant(
          of: find.byType(HomeHeader),
          matching: find.text('Map'),
        ),
        findsNothing,
      );
    });

    testWidgets('shows Add Spot button only when spots exist', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. When spots is empty
      final emptyCubit = _FakeSpotsCubit([]);
      await tester.pumpWidget(buildTestWidget(spotsCubit: emptyCubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(HomeHeader),
          matching: find.text('Add spot'),
        ),
        findsNothing,
      );

      // 2. When spots is NOT empty
      final spotsCubit = _FakeSpotsCubit([
        Spot(
          id: '1',
          name: 'Pharmacy',
          category: SpotCategory.pharmacy,
          latitude: 30.0444,
          longitude: 31.2357,
          savedAt: DateTime(2026, 10, 1),
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(spotsCubit: spotsCubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(HomeHeader),
          matching: find.text('Add spot'),
        ),
        findsOneWidget,
      );
    });
  });

  group('HomeScreen bottom button', () {
    testWidgets(
      'bottom button is shown when no spots exist and hidden when spots exist',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // 1. Empty spots: bottom PrimaryBottomButton should be visible
        final emptyCubit = _FakeSpotsCubit([]);
        await tester.pumpWidget(buildTestWidget(spotsCubit: emptyCubit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(PrimaryBottomButton), findsOneWidget);
        expect(find.text('Save new spot'), findsOneWidget);

        // 2. With spots: bottom PrimaryBottomButton should be hidden
        final populatedCubit = _FakeSpotsCubit([
          Spot(
            id: '1',
            name: 'Home',
            category: SpotCategory.home,
            latitude: 30.0444,
            longitude: 31.2357,
            savedAt: DateTime(2026, 10, 1),
          ),
        ]);
        await tester.pumpWidget(buildTestWidget(spotsCubit: populatedCubit));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(PrimaryBottomButton), findsNothing);
      },
    );
  });

  group('Home 2-Column Cards Grid', () {
    testWidgets('renders CarCard and HomeMapCard side-by-side', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final spotsCubit = _FakeSpotsCubit([]);
      await tester.pumpWidget(buildTestWidget(spotsCubit: spotsCubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CarCard), findsOneWidget);
      expect(find.byType(HomeMapCard), findsOneWidget);

      // HomeMapCard displays Map title and affordances
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('my map'), findsOneWidget);
    });

    testWidgets('tapping HomeMapCard invokes map navigation', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final spotsCubit = _FakeSpotsCubit([]);

      await tester.pumpWidget(
        buildTestWidget(
          spotsCubit: spotsCubit,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap HomeMapCard
      await tester.tap(find.byType(HomeMapCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigation pushed the MapScreen route
      expect(find.text('MapScreen'), findsOneWidget);
    });
  });
}
