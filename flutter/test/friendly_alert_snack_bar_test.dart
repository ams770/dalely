import 'package:feen/shared/theme/app_colors.dart';
import 'package:feen/shared/theme/app_theme.dart';
import 'package:feen/shared/utils/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FriendlyAlert Widget & AppSnackBar Tests', () {
    testWidgets('Renders dark friendly alert in dark mode matching design',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: Center(
              child: FriendlyAlert(
                message: 'Abheet Al Hagar deleted',
                actionLabel: 'Undo',
                onAction: _dummyCallback,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check text is rendered
      expect(find.text('Abheet Al Hagar deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Verify the container has dark background (AppColors.alertDark = 0xFF24262A)
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as ShapeDecoration;
      expect(decoration.color, AppColors.alertDark);
      expect(decoration.shape, isA<StadiumBorder>());

      // Verify checkmark badge
      final badgeFinder = find.byType(FriendlyAlertBadge);
      expect(badgeFinder, findsOneWidget);
      final badgeIcon = find.descendant(
        of: badgeFinder,
        matching: find.byIcon(Icons.check_rounded),
      );
      expect(badgeIcon, findsOneWidget);

      final iconWidget = tester.widget<Icon>(badgeIcon);
      expect(iconWidget.color, AppColors.alertSuccessIcon);

      // Verify action text color
      final actionText = tester.widget<Text>(find.text('Undo'));
      expect(actionText.style?.color, AppColors.alertActionDark);
    });

    testWidgets('Renders light friendly alert in light mode matching design',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: FriendlyAlert(
                message: 'Abheet Al Hagar deleted',
                actionLabel: 'Undo',
                onAction: _dummyCallback,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify container has light background (AppColors.alertLight = Colors.white)
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as ShapeDecoration;
      expect(decoration.color, AppColors.alertLight);
      expect(decoration.shape, isA<StadiumBorder>());

      // Verify action text color is lightPrimary
      final actionText = tester.widget<Text>(find.text('Undo'));
      expect(actionText.style?.color, AppColors.lightPrimary);

      // Verify text inherits lightTextPrimary
      final messageFinder = find.text('Abheet Al Hagar deleted');
      expect(messageFinder, findsOneWidget);
    });

    testWidgets('Tapping action triggers callback', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  AppSnackBar.show(
                    ctx,
                    content: const Text('Spot removed'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        actionTapped = true;
                      },
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Spot removed'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
    });

    testWidgets('Renders properly without action button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FriendlyAlert(
                message: 'Location unavailable',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Location unavailable'), findsOneWidget);
      expect(find.byType(FriendlyAlertAction), findsNothing);
      expect(find.byType(FriendlyAlertBadge), findsOneWidget);
    });

    testWidgets('Renders properly in RTL Arabic directionality',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: FriendlyAlert(
                  message: 'تم حذف أبهيت الحجر',
                  actionLabel: 'تراجع',
                  onAction: _dummyCallback,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تم حذف أبهيت الحجر'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
    });

    testWidgets('Handles very long text without throwing overflow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: Center(
                child: FriendlyAlert(
                  message:
                      'This is an exceptionally long spot description that could cause an overflow if not properly constrained inside the flexible capsule container',
                  actionLabel: 'Undo',
                  onAction: _dummyCallback,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No assertion failure means no overflow!
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppSnackBar appears and has non-zero size on wide screens',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: mainScaffoldMessengerKey,
          home: Material(
            child: Row(
              children: [
                SizedBox(
                  width: 380,
                  child: Scaffold(
                    body: Builder(
                      builder: (ctx) {
                        return ElevatedButton(
                          onPressed: () {
                            AppSnackBar.show(
                              ctx,
                              message: 'Spot deleted',
                              actionLabel: 'Undo',
                              onAction: _dummyCallback,
                            );
                          },
                          child: const Text('Delete Spot'),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Scaffold(
                    body: Container(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Spot'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final alertFinder = find.text('Spot deleted');
      expect(alertFinder, findsWidgets);

      for (final element in alertFinder.evaluate()) {
        final renderBox = element.findRenderObject() as RenderBox?;
        expect(renderBox, isNotNull);
        expect(renderBox!.size.width, greaterThan(0.0));
        expect(renderBox.size.height, greaterThan(0.0));
      }
    });
  });
}

void _dummyCallback() {}
