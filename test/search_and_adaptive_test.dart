import 'package:feen/modules/search/cubit/search_spots_cubit.dart';
import 'package:feen/modules/search/search_spots_screen.dart';
import 'package:feen/modules/settings/settings_screen.dart';
import 'package:feen/modules/spots_map/cubit/spots_map_state.dart';
import 'package:feen/modules/spots_map/spots_map_screen.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/settings/settings_cubit.dart';
import 'package:feen/shared/cubits/settings/settings_state.dart';
import 'package:feen/shared/widgets/center_pin.dart';
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

    testWidgets('isSplitLayout is false in portrait even when screen is wide',
        (tester) async {
      // Wide screen in portrait: 700 x 1000
      tester.view.physicalSize = const Size(700 * 2.0, 1000 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isPortrait;
      late bool isLandscape;
      late bool isWide;
      late bool isSplit;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isPortrait = context.isPortrait;
              isLandscape = context.isLandscape;
              isWide = context.isWideScreen;
              isSplit = context.isSplitLayout;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isPortrait, isTrue);
      expect(isLandscape, isFalse);
      expect(isWide, isTrue);
      expect(isSplit, isFalse, reason: 'Portrait mode must never split the layout');
    });

    testWidgets('isSplitLayout is true in landscape on wide screen',
        (tester) async {
      // Wide screen in landscape: 1000 x 700
      tester.view.physicalSize = const Size(1000 * 2.0, 700 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isPortrait;
      late bool isLandscape;
      late bool isWide;
      late bool isSplit;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isPortrait = context.isPortrait;
              isLandscape = context.isLandscape;
              isWide = context.isWideScreen;
              isSplit = context.isSplitLayout;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isPortrait, isFalse);
      expect(isLandscape, isTrue);
      expect(isWide, isTrue);
      expect(isSplit, isTrue);
    });

    testWidgets('identifies left screen on iPhone Duo and positions rail on left',
        (tester) async {
      // iPhone Duo Left Screen: 466 x 678, padding.right is 0 (touches hinge)
      tester.view.physicalSize = const Size(466 * 3.0, 678 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = FakeViewPadding.zero;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      late bool isDuoFolded;
      late bool isDuoLeft;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isDuoFolded = context.isDuoFolded;
              isDuoLeft = context.isDuoLeftScreen;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isDuoFolded, isTrue);
      expect(isDuoLeft, isTrue,
          reason: 'Left screen has no right hardware status rail');
    });

    testWidgets('identifies right screen on iPhone Duo when right status rail exists',
        (tester) async {
      // iPhone Duo Right Screen: 466 x 678, padding.right >= 35 (hardware status rail)
      tester.view.physicalSize = const Size(466 * 3.0, 678 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(right: 48 * 3.0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      late bool isDuoFolded;
      late bool isDuoLeft;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isDuoFolded = context.isDuoFolded;
              isDuoLeft = context.isDuoLeftScreen;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isDuoFolded, isTrue);
      expect(isDuoLeft, isFalse,
          reason: 'Right screen has right hardware status rail');
    });


    testWidgets(
        'SpotsMapScreen centers pin within map pane width, not window width on wide screens',
        (tester) async {
      // Wide screen: 1000 x 800
      tester.view.physicalSize = const Size(1000 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSpotsCubit = _FakeSpotsCubit([]);
      final fakeLocationCubit = _FakeLocationCubit();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: fakeSpotsCubit),
            BlocProvider<LocationCubit>.value(value: fakeLocationCubit),
            BlocProvider<AdaptiveNavCubit>.value(value: AdaptiveNavCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Row(
                children: [
                  SizedBox(width: 400),
                  Expanded(
                    child: SpotsMapScreen(
                      initialMode: SpotsMapMode.addSpot,
                      isEmbedded: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The right pane has width 1000 - 400 = 600.
      // The CenterPin's horizontal center must be at 400 + 600 / 2 = 700,
      // NOT (1000 / 2 = 500) which would be off towards the pane's left edge (500 - 400 = 100).
      expect(find.byType(CenterPin), findsOneWidget);
      final centerPinCenter = tester.getCenter(find.byType(CenterPin));
      expect(centerPinCenter.dx, closeTo(700.0, 1.0));
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

    test('availableCategories contains only categories of existing spots', () {
      // spots have pharmacy and home
      final spotsCubit = _FakeSpotsCubit([spot1, spot3]);
      final searchCubit = SearchSpotsCubit(spotsCubit: spotsCubit);

      expect(searchCubit.state.availableCategories, contains(SpotCategory.pharmacy));
      expect(searchCubit.state.availableCategories, contains(SpotCategory.home));
      expect(searchCubit.state.availableCategories.contains(SpotCategory.gym), isFalse);
      expect(searchCubit.state.availableCategories.contains(SpotCategory.fuel), isFalse);
      expect(searchCubit.state.availableCategories.length, 2);

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

    testWidgets('renders category filter chips only for categories with existing spots',
        (tester) async {
      final now = DateTime(2026, 10, 11);
      final spotPark = Spot(
        id: '1',
        name: 'Central Park',
        category: SpotCategory.park,
        latitude: 30.0,
        longitude: 31.0,
        savedAt: now,
      );
      final fakeSpotsCubit = _FakeSpotsCubit([spotPark]);

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

      // Category chip for Park should be visible
      expect(find.text('Park'), findsOneWidget);
      // Other categories with no spots should NOT be visible
      expect(find.text('Gym'), findsNothing);
      expect(find.text('Mosque'), findsNothing);
      expect(find.text('Fuel'), findsNothing);
    });

    testWidgets(
        'SettingsScreen automatically pops and activates detail pane when expanding to wide two-pane layout',
        (tester) async {
      // Start in compact portrait mode (small screen)
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navCubit = AdaptiveNavCubit();
      final settingsCubit = _FakeSettingsCubit();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AdaptiveNavCubit>.value(value: navCubit),
            BlocProvider<SettingsCubit>.value(value: settingsCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open Settings standalone
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(navCubit.state.detailPane, DetailPaneType.map);

      // Expand to wide landscape screen (two-pane layout)
      tester.view.physicalSize = const Size(1000 * 2.0, 700 * 2.0);
      await tester.pump();
      await tester.pumpAndSettle();

      // Standalone SettingsScreen has popped
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);
      // AdaptiveNavCubit has updated to settings detail pane
      expect(navCubit.state.detailPane, DetailPaneType.settings);
    });

    testWidgets(
        'SearchSpotsScreen automatically pops, activates detail pane, and preserves search query on screen expansion',
        (tester) async {
      // Start in compact portrait mode (small screen)
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navCubit = AdaptiveNavCubit();
      final now = DateTime.now();
      final spot = Spot(
        id: 'spot_1',
        name: 'Grand Hospital',
        category: SpotCategory.hospital,
        latitude: 30.0,
        longitude: 31.0,
        savedAt: now,
      );
      final fakeSpotsCubit = _FakeSpotsCubit([spot]);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AdaptiveNavCubit>.value(value: navCubit),
            BlocProvider<SpotsCubit>.value(value: fakeSpotsCubit),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SearchSpotsScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Search'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Search
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchSpotsScreen), findsOneWidget);
      expect(navCubit.state.detailPane, DetailPaneType.map);

      // Enter query
      await tester.enterText(find.byType(TextField), 'Hospital');
      await tester.pumpAndSettle();

      // Expand to wide landscape screen (two-pane layout)
      tester.view.physicalSize = const Size(1000 * 2.0, 700 * 2.0);
      await tester.pump();
      await tester.pumpAndSettle();

      // Standalone SearchSpotsScreen popped
      expect(find.text('Open Search'), findsOneWidget);
      expect(find.byType(SearchSpotsScreen), findsNothing);
      // AdaptiveNavCubit has updated to search detail pane with query preserved
      expect(navCubit.state.detailPane, DetailPaneType.search);
      expect(navCubit.state.searchQuery, 'Hospital');
    });
  });
}

class _FakeSettingsCubit extends Cubit<SettingsState> implements SettingsCubit {
  _FakeSettingsCubit() : super(const SettingsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit() : super(const LocationState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
