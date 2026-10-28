import 'package:feen/shared/constants/spot_categories.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';
import 'package:feen/shared/models/spot.dart';
import 'package:feen/shared/widgets/spot_adaptive_menu.dart';
import 'package:feen/shared/widgets/spot_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SpotCard renders and triggers tap', (tester) async {
    final spot = Spot(
      id: 'spot-1',
      name: 'Gym',
      category: SpotCategory.gym,
      latitude: 30.0,
      longitude: 31.0,
      savedAt: DateTime.now(),
    );

    var tapCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SpotCard(
            spot: spot,
            onShowOnMap: () => tapCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Gym'), findsOneWidget);
    await tester.tap(find.text('Gym'));
    expect(tapCalled, isTrue);
  });

  testWidgets('SpotAdaptiveMenu.show renders menu items and selects action', (tester) async {
    final spot = Spot(
      id: 'spot-1',
      name: 'Gym',
      category: SpotCategory.gym,
      latitude: 30.0,
      longitude: 31.0,
      savedAt: DateTime.now(),
    );

    var shareCalled = false;
    BuildContext? testContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const SizedBox(width: 100, height: 100);
            },
          ),
        ),
      ),
    );

    SpotAdaptiveMenu.show(
      context: testContext!,
      spot: spot,
      onShare: () => shareCalled = true,
      onEdit: () {},
      onOpenInMaps: () {},
      onDelete: () {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Edit spot'), findsOneWidget);
    expect(find.text('Open in Maps'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(shareCalled, isTrue);
  });

  testWidgets('SpotCard long press opens adaptive menu at the end of the row', (tester) async {
    final spot = Spot(
      id: 'spot-1',
      name: 'Gym',
      category: SpotCategory.gym,
      latitude: 30.0,
      longitude: 31.0,
      savedAt: DateTime.now(),
    );

    var shareCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: SpotCard(
                spot: spot,
                onShare: () => shareCalled = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gym'), findsOneWidget);
    await tester.longPress(find.text('Gym'));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Edit spot'), findsOneWidget);
    expect(find.text('Open in Maps'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Verify the menu opens aligned towards the end of the 360-wide card row (center is at x=400, end is at x=580)
    final shareTopLeft = tester.getTopLeft(find.text('Share'));
    expect(shareTopLeft.dx, greaterThan(350));

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(shareCalled, isTrue);
  });

  testWidgets('ParkingHistory card long-press opens menu without Edit option', (tester) async {
    final spot = Spot(
      id: 'parking_1',
      name: 'Car',
      category: SpotCategory.car,
      latitude: 24.7,
      longitude: 46.7,
      savedAt: DateTime(2026, 10, 26, 17, 41),
      status: SpotStatus.found,
      parkedDuration: const Duration(minutes: 15),
    );

    var shareCalled = false;
    BuildContext? testContext;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              testContext = ctx;
              return const SizedBox(width: 100, height: 100);
            },
          ),
        ),
      ),
    );

    SpotAdaptiveMenu.show(
      context: testContext!,
      spot: spot,
      onShare: () => shareCalled = true,
      onOpenInMaps: () {},
      onDelete: () {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Edit spot'), findsNothing);
    expect(find.text('Open in Maps'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(shareCalled, isTrue);
  });
}

