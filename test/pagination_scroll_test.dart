import 'package:feen/modules/home/cubit/home_cubit.dart';
import 'package:feen/modules/home/home_screen.dart';
import 'package:feen/modules/parking_history/cubit/parking_history_cubit.dart';
import 'package:feen/modules/parking_history/parking_history_screen.dart';
import 'package:feen/modules/search/cubit/search_spots_cubit.dart';
import 'package:feen/modules/search/search_spots_screen.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit(
    List<Spot> initialSpots, {
    Spot? car,
    List<Spot>? parkingHistory,
    SpotSortOrder sortOrder = SpotSortOrder.dateDesc,
  }) : super(SpotsState(
          spots: initialSpots,
          car: car,
          parkingHistory: parkingHistory ?? const [],
          sortOrder: sortOrder,
        ));

  void updateSpots(List<Spot> newSpots) {
    emit(state.copyWith(spots: newSpots));
  }

  void updateSortOrder(SpotSortOrder order) {
    emit(state.copyWith(sortOrder: order));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationCubit extends Cubit<LocationState>
    implements LocationCubit {
  _FakeLocationCubit()
      : super(const LocationState(access: LocationAccess.granted));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsCubit extends Cubit<SettingsState>
    implements SettingsCubit {
  _FakeSettingsCubit()
      : super(const SettingsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCarProximityCubit extends Cubit<CarProximityState>
    implements CarProximityCubit {
  _FakeCarProximityCubit() : super(const CarProximityState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Spot> _generateSpots(int count, {SpotStatus status = SpotStatus.none}) {
  final now = DateTime(2026, 10, 14, 12, 0);
  return List.generate(
    count,
    (i) => Spot(
      id: 'spot_$i',
      name: 'Spot $i',
      category: SpotCategory.market,
      latitude: 30.0 + (i * 0.001),
      longitude: 31.0 + (i * 0.001),
      savedAt: now.subtract(Duration(minutes: i)),
      status: status,
      parkedDuration: status == SpotStatus.found ? const Duration(minutes: 10) : null,
    ),
  );
}

void main() {
  group('ParkingHistory pagination', () {
    test('ParkingHistoryCubit initializes with 50 and loads 50 by page', () {
      final spots = _generateSpots(120, status: SpotStatus.found);
      final fakeSpotsCubit = _FakeSpotsCubit([], parkingHistory: spots);
      final cubit = ParkingHistoryCubit(spotsCubit: fakeSpotsCubit);

      expect(cubit.state.visibleCount, 50);

      // Load more -> 100
      cubit.loadMore();
      expect(cubit.state.visibleCount, 100);

      // Load more -> 150 (all 120 covered)
      cubit.loadMore();
      expect(cubit.state.visibleCount, 150);

      // Subsequent call does nothing because visibleCount (150) >= total (120)
      cubit.loadMore();
      expect(cubit.state.visibleCount, 150);

      cubit.close();
      fakeSpotsCubit.close();
    });

    testWidgets('ParkingHistoryScreen initially displays 50 items and has scrollController',
        (tester) async {
      final spots = _generateSpots(70, status: SpotStatus.found);
      final fakeSpotsCubit = _FakeSpotsCubit([], parkingHistory: spots);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: fakeSpotsCubit),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ParkingHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find ListView and verify itemCount is 50 (first page)
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);
      final listView = tester.widget<ListView>(listViewFinder);
      expect(listView.childrenDelegate.estimatedChildCount, 50);

      fakeSpotsCubit.close();
    });
  });

  group('SearchSpots pagination', () {
    test('SearchSpotsCubit initializes with 50 and loads 50 by page', () {
      final spots = _generateSpots(120);
      final fakeSpotsCubit = _FakeSpotsCubit(spots);
      final cubit = SearchSpotsCubit(spotsCubit: fakeSpotsCubit);

      expect(cubit.state.visibleCount, 50);
      expect(cubit.state.matchingSpots.length, 120);

      // Load more -> 100
      cubit.loadMore();
      expect(cubit.state.visibleCount, 100);

      // Changing query resets visibleCount to 50
      cubit.onQueryChanged('Spot 1');
      expect(cubit.state.visibleCount, 50);

      cubit.close();
      fakeSpotsCubit.close();
    });

    testWidgets('SearchSpotsScreen initially renders first 50 results',
        (tester) async {
      final spots = _generateSpots(80);
      final fakeSpotsCubit = _FakeSpotsCubit(spots);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: fakeSpotsCubit),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SearchSpotsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The vertical ListView for results has 80 matching spots, but displayedSpots is 50
      final verticalListViewFinder = find.byWidgetPredicate(
        (w) => w is ListView && w.scrollDirection == Axis.vertical,
      );
      expect(verticalListViewFinder, findsOneWidget);
      final listView = tester.widget<ListView>(verticalListViewFinder);
      // ListView.separated childrenDelegate count includes separators: 50 items + 49 separators = 99
      expect(listView.childrenDelegate.estimatedChildCount, 50 * 2 - 1);

      fakeSpotsCubit.close();
    });
  });

  group('Home pagination', () {
    test('HomeCubit initializes with 50 and loads 50 by page', () async {
      final spots = _generateSpots(120);
      final fakeSpotsCubit = _FakeSpotsCubit(spots);
      final cubit = HomeCubit(spotsCubit: fakeSpotsCubit);

      expect(cubit.state.visibleCount, 50);

      // Load more -> 100
      cubit.loadMore();
      expect(cubit.state.visibleCount, 100);

      // Changing sort order resets visibleCount back to 50
      fakeSpotsCubit.updateSortOrder(SpotSortOrder.name);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.visibleCount, 50);

      cubit.close();
      fakeSpotsCubit.close();
    });

    testWidgets('HomeScreen renders first 50 saved spots',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final spots = _generateSpots(80);
      final fakeSpotsCubit = _FakeSpotsCubit(spots);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: fakeSpotsCubit),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
            BlocProvider<SettingsCubit>.value(value: _FakeSettingsCubit()),
            BlocProvider<AdaptiveNavCubit>.value(value: AdaptiveNavCubit()),
            BlocProvider<CarProximityCubit>.value(value: _FakeCarProximityCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the sliver list for saved spots
      final sliverLists = find.byType(SliverList);
      expect(sliverLists, findsWidgets);

      // The spots sliver list has childCount == 50
      final spotsSliver = tester.widget<SliverList>(sliverLists.last);
      expect(spotsSliver.delegate.estimatedChildCount, 50);

      fakeSpotsCubit.close();
    });
  });
}
