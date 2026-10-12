import 'package:feen/modules/search/cubit/search_spots_cubit.dart';
import 'package:feen/modules/search/search_spots_screen.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import 'package:feen/shared/cubits/adaptive_nav/adaptive_nav_state.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/cubits/location/location_state.dart';
import 'package:feen/shared/cubits/spots/spots_cubit.dart';
import 'package:feen/shared/cubits/spots/spots_state.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/theme/app_theme.dart';
import 'package:feen/shared/utils/adaptive_layout_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit(List<Spot> initialSpots, {Spot? car})
      : super(SpotsState(spots: initialSpots, car: car));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AdaptiveNavCubit', () {
    test('initializes on Map detail pane with null selected spot', () {
      final cubit = AdaptiveNavCubit();
      expect(cubit.state.detailPane, DetailPaneType.map);
      expect(cubit.state.selectedSpotId, isNull);
    });

    test('switches between detail panes and restores map on closeDetail', () {
      final cubit = AdaptiveNavCubit();

      cubit.openSearch();
      expect(cubit.state.detailPane, DetailPaneType.search);

      cubit.openSaveSpot();
      expect(cubit.state.detailPane, DetailPaneType.saveSpot);

      cubit.openSettings();
      expect(cubit.state.detailPane, DetailPaneType.settings);

      cubit.closeDetail();
      expect(cubit.state.detailPane, DetailPaneType.map);

      cubit.showMap(spotId: 'car_123');
      expect(cubit.state.detailPane, DetailPaneType.map);
      expect(cubit.state.selectedSpotId, 'car_123');
    });

    test('showMap updates requestTimestamp allowing repeated focus events', () {
      final cubit = AdaptiveNavCubit();
      cubit.showMap();
      final ts1 = cubit.state.requestTimestamp;
      expect(ts1, greaterThan(0));

      cubit.showMap();
      final ts2 = cubit.state.requestTimestamp;
      expect(ts2, greaterThanOrEqualTo(ts1));
    });
  });

  group('AdaptiveLayoutContext & Foldable/Tablet Layouts', () {
    testWidgets('identifies foldable dimensions (50% / 50%) for unfolded foldables',
        (tester) async {
      tester.view.physicalSize = const Size(720 * 2.0, 900 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isWide;
      late bool isFoldable;
      late bool isTablet;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isWide = context.isWideScreen;
              isFoldable = context.isFoldableDevice;
              isTablet = context.isTabletDevice;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isWide, isTrue);
      expect(isFoldable, isTrue);
      expect(isTablet, isFalse);
    });

    testWidgets('identifies tablet dimensions for large screens (width >= 840)',
        (tester) async {
      tester.view.physicalSize = const Size(1024 * 2.0, 768 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isWide;
      late bool isFoldable;
      late bool isTablet;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isWide = context.isWideScreen;
              isFoldable = context.isFoldableDevice;
              isTablet = context.isTabletDevice;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isWide, isTrue);
      expect(isFoldable, isFalse);
      expect(isTablet, isTrue);
    });
  });

  group('SearchSpotsCubit', () {
    final now = DateTime(2026, 10, 11);
    final spot1 = Spot(
      id: '1',
      name: 'صيدلية العزبي',
      category: SpotCategory.pharmacy,
      latitude: 30.0,
      longitude: 31.0,
      savedAt: now,
    );
    final spot2 = Spot(
      id: '2',
      name: 'Metro Market',
      category: SpotCategory.market,
      latitude: 30.1,
      longitude: 31.1,
      savedAt: now,
    );
    final spot3 = Spot(
      id: '3',
      name: 'بيت العائلة',
      category: SpotCategory.home,
      latitude: 30.2,
      longitude: 31.2,
      savedAt: now,
    );
    final carSpot = Spot(
      id: 'car',
      name: 'عربيتي',
      category: SpotCategory.car,
      latitude: 30.05,
      longitude: 31.05,
      savedAt: now,
    );

    test('initial state contains all spots including car', () {
      final spotsCubit = _FakeSpotsCubit([spot1, spot2, spot3], car: carSpot);
      final searchCubit = SearchSpotsCubit(spotsCubit: spotsCubit);

      expect(searchCubit.state.matchingSpots.length, 4);
      expect(searchCubit.state.matchingSpots, containsAll([spot1, spot2, spot3, carSpot]));
      searchCubit.close();
    });

    test('filters case-insensitively for English spot names', () {
      final spotsCubit = _FakeSpotsCubit([spot1, spot2, spot3]);
      final searchCubit = SearchSpotsCubit(spotsCubit: spotsCubit);

      searchCubit.onQueryChanged('metro');
      expect(searchCubit.state.matchingSpots.length, 1);
      expect(searchCubit.state.matchingSpots.first.id, '2');

      searchCubit.clearQuery();
      expect(searchCubit.state.matchingSpots.length, 3);
      searchCubit.close();
    });

    test('normalizes Arabic characters (alef and taa marbuta) in search', () {
      final spotsCubit = _FakeSpotsCubit([spot1, spot2, spot3]);
      final searchCubit = SearchSpotsCubit(spotsCubit: spotsCubit);

      // Search with "صيدليه" (ending in ه) should match "صيدلية" (ending in ة)
      searchCubit.onQueryChanged('صيدليه');
      expect(searchCubit.state.matchingSpots.length, 1);
      expect(searchCubit.state.matchingSpots.first.id, '1');

      // Search with "العزبي" should match
      searchCubit.onQueryChanged('العزبي');
      expect(searchCubit.state.matchingSpots.length, 1);

      searchCubit.close();
    });

    test('toggling category filters spots and combining with query works', () {
      final spotsCubit = _FakeSpotsCubit([spot1, spot2, spot3]);
      final searchCubit = SearchSpotsCubit(spotsCubit: spotsCubit);

      searchCubit.toggleCategory(SpotCategory.pharmacy);
      expect(searchCubit.state.matchingSpots.length, 1);
      expect(searchCubit.state.matchingSpots.first.category, SpotCategory.pharmacy);

      // Untoggle restores all
      searchCubit.toggleCategory(SpotCategory.pharmacy);
      expect(searchCubit.state.matchingSpots.length, 3);

      searchCubit.close();
    });
  });

  group('SearchSpotsScreen Widget', () {
    testWidgets('renders search input field and displays matching spot',
        (tester) async {
      final now = DateTime(2026, 10, 11);
      final spot = Spot(
        id: '1',
        name: 'صيدلية العزبي',
        category: SpotCategory.pharmacy,
        latitude: 30.0,
        longitude: 31.0,
        savedAt: now,
      );
      final fakeSpotsCubit = _FakeSpotsCubit([spot]);

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

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('صيدلية العزبي'), findsOneWidget);
      expect(find.byType(BackButtonIcon), findsOneWidget);
    });
  });
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit() : super(const LocationState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
