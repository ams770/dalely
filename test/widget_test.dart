import 'package:feen/modules/home/cubit/parking_timer_cubit.dart';
import 'package:feen/modules/save_spot/cubit/save_spot_state.dart';
import 'package:feen/shared/constants/app_assets.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/cubits/car_proximity/car_proximity_cubit.dart';
import 'package:feen/shared/models/app_settings.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/modules/settings/settings_screen.dart';
import 'package:feen/shared/cubits/settings/settings_cubit.dart';
import 'package:feen/shared/cubits/settings/settings_state.dart';
import 'package:feen/shared/data/settings_repository.dart';
import 'package:feen/shared/cubits/spots/spots_cubit.dart';
import 'package:feen/shared/cubits/spots/spots_state.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';
import 'package:feen/shared/services/marker_icon_cache.dart';
import 'package:feen/shared/theme/app_theme.dart';
import 'package:feen/shared/utils/distance_formatter.dart';
import 'package:feen/shared/utils/duration_formatter.dart';
import 'package:feen/shared/utils/spot_link_builder.dart';
import 'package:feen/shared/constants/app_links.dart';
import 'package:feen/shared/widgets/car_arrival_dialog.dart';
import 'package:feen/shared/widgets/circle_icon_button.dart';
import 'package:feen/modules/spots_map/widgets/selected_spot_card.dart';
import 'package:feen/shared/cubits/car_tracking/car_tracking_cubit.dart';
import 'package:feen/shared/models/car_tracking_state.dart';
import 'package:feen/shared/cubits/location/location_cubit.dart';
import 'package:feen/shared/cubits/location/location_state.dart';
import 'package:feen/shared/widgets/category_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarkerIconCache', () {
    test('computes carMarkerAnchor accurately for all zoom tiers', () {
      final cache = MarkerIconCache();
      final highAnchor = cache.carMarkerAnchor(MarkerZoomTier.high);
      final mediumAnchor = cache.carMarkerAnchor(MarkerZoomTier.medium);
      final lowAnchor = cache.carMarkerAnchor(MarkerZoomTier.low);

      expect(highAnchor.dx, 0.5);
      expect(highAnchor.dy, 0.83);
      expect(mediumAnchor.dx, 0.5);
      expect(mediumAnchor.dy, 0.81);
      expect(lowAnchor.dx, 0.5);
      expect(lowAnchor.dy, 0.5);
    });

    test('provides increased marker sizes for all zoom tiers', () {
      expect(MarkerZoomTier.high.pinSize, 88.0);
      expect(MarkerZoomTier.medium.pinSize, 58.0);
      expect(MarkerZoomTier.low.pinSize, 38.0);
    });

    test('getCarMarker returns a BitmapDescriptor without throwing', () async {
      final cache = MarkerIconCache();
      final marker = await cache.getCarMarker();
      expect(marker, isNotNull);
    });
  });

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
      expect(cubit.state.targetThresholdMeters, 15.0);
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
      expect(AssetProvider.locationLottie, 'assets/lottie/location.json');
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

  group('CarArrivalDialog', () {
    testWidgets('renders full page with car image and Egyptian Arabic button',
        (tester) async {
      var foundCarPressed = false;
      var cantSeeCarPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar', 'EG'),
          home: Scaffold(
            body: CarArrivalDialog(
              onFoundCar: () => foundCarPressed = true,
              onCantSeeCar: () => cantSeeCarPressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('لسه مشوفتش العربيه'), findsOneWidget);
      expect(foundCarPressed, isFalse);

      await tester.tap(find.text('لسه مشوفتش العربيه'));
      await tester.pumpAndSettle();
      expect(cantSeeCarPressed, isTrue);
    });

    testWidgets('renders Dialog.fullscreen on mobile screen (< 600 dp)',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar', 'EG'),
          home: Scaffold(
            body: CarArrivalDialog(
              onFoundCar: () {},
              onCantSeeCar: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialog = tester.widget<Dialog>(dialogFinder);
      expect(dialog.insetPadding, EdgeInsets.zero);
    });

    testWidgets('renders bounded dialog in available area on foldable/tablet screen',
        (tester) async {
      tester.view.physicalSize = const Size(720 * 2.0, 900 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar', 'EG'),
          home: Scaffold(
            body: CarArrivalDialog(
              onFoundCar: () {},
              onCantSeeCar: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(Dialog);
      expect(dialogFinder, findsOneWidget);
      final dialog = tester.widget<Dialog>(dialogFinder);
      expect(dialog.alignment, AlignmentDirectional.centerEnd);
      expect(dialog.insetPadding, isNot(EdgeInsets.zero));
    });
  });

  group('SettingsScreen Header', () {
    testWidgets('renders CircleIconButton back button in AppBar',
        (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: _FakeSettingsCubit()),
            BlocProvider<SpotsCubit>.value(value: _FakeSpotsCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleIconButton), findsOneWidget);
      expect(find.byType(BackButtonIcon), findsOneWidget);
    });

    testWidgets('renders website, privacy policy, and whatsapp in about section',
        (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: _FakeSettingsCubit()),
            BlocProvider<SpotsCubit>.value(value: _FakeSpotsCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Website'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Contact via WhatsApp'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
    });
  });

  group('AppLinks', () {
    test('contains production Dalely website, privacy policy, WhatsApp, support email, and play store', () {
      expect(AppLinks.website, 'https://dalely.firebaseapp.com/');
      expect(AppLinks.privacyPolicy, 'https://dalely.firebaseapp.com/#privacy');
      expect(AppLinks.whatsApp, 'https://wa.me/201123225592');
      expect(AppLinks.supportEmail, 'salem.dev.77@gmail.com');
      expect(AppLinks.playStore, 'https://play.google.com/store/apps/details?id=com.dalely.app');
      expect(AppLinks.playStoreMarket, 'market://details?id=com.dalely.app');
    });
  });

  group('SelectedSpotCard', () {
    testWidgets('renders car image from AssetProvider when spot is car', (tester) async {
      final carSpot = Spot(
        id: 'car',
        name: 'My Car',
        category: SpotCategory.car,
        latitude: 30.0444,
        longitude: 31.2357,
        savedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: _FakeSettingsCubit()),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
            BlocProvider<CarTrackingCubit>.value(value: _FakeCarTrackingCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SelectedSpotCard(
                spot: carSpot,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final imageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image == AssetProvider.carImage,
      );
      expect(imageFinder, findsOneWidget);
      expect(find.byType(CategoryBadge), findsNothing);
    });

    testWidgets('renders CategoryBadge when spot is not car', (tester) async {
      final marketSpot = Spot(
        id: 'market_1',
        name: 'City Market',
        category: SpotCategory.market,
        latitude: 30.0444,
        longitude: 31.2357,
        savedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: _FakeSettingsCubit()),
            BlocProvider<LocationCubit>.value(value: _FakeLocationCubit()),
            BlocProvider<CarTrackingCubit>.value(value: _FakeCarTrackingCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SelectedSpotCard(
                spot: marketSpot,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CategoryBadge), findsOneWidget);
      final imageFinder = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image == AssetProvider.carImage,
      );
      expect(imageFinder, findsNothing);
    });
  });

  group('SettingsCubit Initialization', () {
    test('initializes state synchronously with saved theme without flashing system theme', () {
      final repo = _FakeSettingsRepository(
        settings: const AppSettings(themeMode: ThemeMode.light),
      );
      final cubit = SettingsCubit(repo);
      expect(cubit.state.themeMode, ThemeMode.light);
      cubit.close();
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({this.settings = const AppSettings()});
  final AppSettings settings;

  @override
  AppSettings load() => settings;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsCubit extends Cubit<SettingsState> implements SettingsCubit {
  _FakeSettingsCubit() : super(const SettingsState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

class _FakeCarTrackingCubit extends Cubit<CarTrackingState> implements CarTrackingCubit {
  _FakeCarTrackingCubit() : super(const CarTrackingState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
