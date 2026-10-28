import 'dart:convert';

import 'package:feen/modules/home/home_screen.dart';
import 'package:feen/modules/home/widgets/export_spots_sheet.dart';
import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/constants/storage_keys.dart';
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
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/theme/app_theme.dart';
import 'package:feen/shared/utils/spots_csv_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpotsCsvBuilder', () {
    test('build returns empty string when spots list is empty', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(SpotsCsvBuilder.build([], l10n: l10n), '');
      expect(SpotsCsvBuilder.buildBytes([], l10n: l10n), isEmpty);
    });

    test('build formats headers and spot rows with Google Maps URL', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final spots = [
        Spot(
          id: '1',
          name: 'Central Pharmacy',
          category: SpotCategory.pharmacy,
          latitude: 30.0444,
          longitude: 31.2357,
          savedAt: DateTime(2026, 10, 1, 10, 0),
        ),
        Spot(
          id: '2',
          name: 'Home, Sweet "Home"',
          category: SpotCategory.home,
          latitude: 30.0500,
          longitude: 31.2400,
          savedAt: DateTime(2026, 10, 2, 10, 0),
        ),
      ];

      final csv = SpotsCsvBuilder.build(spots, l10n: l10n);
      final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();

      expect(lines.length, 3);
      expect(lines[0], 'Name,Latitude,Longitude,Google Maps URL');
      // Sorted by savedAt descending
      expect(
        lines[1],
        '"Home, Sweet ""Home""",30.05,31.24,"https://maps.google.com/?q=30.05,31.24"',
      );
      expect(
        lines[2],
        'Central Pharmacy,30.0444,31.2357,"https://maps.google.com/?q=30.0444,31.2357"',
      );
    });

    test('orders parked car first and provides fallback name', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final spots = [
        Spot(
          id: '1',
          name: 'Market',
          category: SpotCategory.market,
          latitude: 30.1,
          longitude: 31.1,
          savedAt: DateTime(2026, 10, 5),
        ),
        Spot(
          id: StorageKeys.carId,
          name: '',
          category: SpotCategory.car,
          latitude: 30.0,
          longitude: 31.0,
          savedAt: DateTime(2026, 10, 1),
        ),
      ];

      final csv = SpotsCsvBuilder.build(spots, l10n: l10n);
      final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();

      expect(lines.length, 3);
      expect(lines[1], 'My car,30.0,31.0,"https://maps.google.com/?q=30.0,31.0"');
      expect(lines[2], 'Market,30.1,31.1,"https://maps.google.com/?q=30.1,31.1"');
    });

    test('buildBytes prepends UTF-8 BOM', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      final spots = [
        Spot(
          id: '1',
          name: 'سوبرماركت المدينة',
          category: SpotCategory.market,
          latitude: 24.7136,
          longitude: 46.6753,
          savedAt: DateTime.now(),
        ),
      ];

      final bytes = SpotsCsvBuilder.buildBytes(spots, l10n: l10n);
      expect(bytes.length, greaterThan(3));
      // UTF-8 BOM is 0xEF, 0xBB, 0xBF
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);

      // Verify the decoded string contains Arabic text
      final decoded = utf8.decode(bytes.sublist(3));
      expect(decoded.contains('سوبرماركت المدينة'), isTrue);
    });
  });

  group('ExportSpotsSheet Widget', () {
    testWidgets('renders Excel and Text options with icons and text',
        (tester) async {
      final spots = [
        Spot(
          id: '1',
          name: 'Office',
          category: SpotCategory.work,
          latitude: 30.0,
          longitude: 31.0,
          savedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ExportSpotsSheet(spots: spots),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export spots'), findsOneWidget);
      expect(find.text('Export as Excel (CSV)'), findsOneWidget);
      expect(find.text('Export as text'), findsOneWidget);
      expect(find.byIcon(Icons.table_chart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.text_snippet_rounded), findsOneWidget);
    });

    testWidgets('tapping options dismisses the sheet', (tester) async {
      final spots = [
        Spot(
          id: '1',
          name: 'Office',
          category: SpotCategory.work,
          latitude: 30.0,
          longitude: 31.0,
          savedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ExportSpotsSheet(spots: spots),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(ExportSpotsSheet), findsOneWidget);

      await tester.tap(find.text('Export as text'));
      await tester.pumpAndSettle();
      expect(find.byType(ExportSpotsSheet), findsNothing);
    });
  });

  group('HomeScreen Export Button', () {
    testWidgets('renders export button beside search and opens sheet',
        (tester) async {
      final spot = Spot(
        id: '1',
        name: 'My Store',
        category: SpotCategory.market,
        latitude: 30.0,
        longitude: 31.0,
        savedAt: DateTime.now(),
      );

      final fakeSpotsCubit = _FakeSpotsCubit([spot]);
      final fakeLocationCubit = _FakeLocationCubit();
      final fakeSettingsCubit = _FakeSettingsCubit();
      final fakeAdaptiveCubit = AdaptiveNavCubit();
      final fakeCarProximityCubit = _FakeCarProximityCubit();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SpotsCubit>.value(value: fakeSpotsCubit),
            BlocProvider<LocationCubit>.value(value: fakeLocationCubit),
            BlocProvider<SettingsCubit>.value(value: fakeSettingsCubit),
            BlocProvider<AdaptiveNavCubit>.value(value: fakeAdaptiveCubit),
            BlocProvider<CarProximityCubit>.value(value: fakeCarProximityCubit),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Export button is present beside search
      expect(find.byTooltip('Export data'), findsOneWidget);
      expect(find.byTooltip('Search spots'), findsOneWidget);

      // Tap export button opens the ExportSpotsSheet
      await tester.tap(find.byTooltip('Export data'));
      await tester.pumpAndSettle();

      expect(find.byType(ExportSpotsSheet), findsOneWidget);
      expect(find.text('Export spots'), findsOneWidget);
    });
  });
}

class _FakeSpotsCubit extends Cubit<SpotsState> implements SpotsCubit {
  _FakeSpotsCubit(List<Spot> initialSpots, {Spot? car})
      : super(SpotsState(spots: initialSpots, car: car));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocationCubit extends Cubit<LocationState> implements LocationCubit {
  _FakeLocationCubit() : super(const LocationState());

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

