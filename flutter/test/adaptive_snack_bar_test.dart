import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;
import 'package:feen/shared/utils/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSnackBar adaptive margin on foldables and normal screens', () {
    testWidgets('Normal phone screen uses symmetric 20/100 margin',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const Center(child: Text('Phone'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final margin = AppSnackBar.computeMargin(capturedContext);
      expect(margin.left, 20.0);
      expect(margin.right, 20.0);
      expect(margin.bottom, 100.0);
      expect(margin.top, 100.0);
    });

    testWidgets(
        'Foldable screen (width 700) places snackbar inside left part when invoked from left',
        (tester) async {
      tester.view.physicalSize = const Size(700, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late BuildContext leftContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (ctx) {
                      leftContext = ctx;
                      return const Center(child: Text('Left Pane'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Center(child: Text('Right Pane'))),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final margin = AppSnackBar.computeMargin(leftContext);
      expect(margin.left, 20.0);
      // (700 + 12)/2 + 20 = 356 + 20 = 376
      expect(margin.right, 376.0);
      expect(margin.bottom, 100.0);

      // Verify the snackbar bounds stay within the left half (0 to 344)
      final snackBarRightEdge = 700 - margin.right;
      expect(snackBarRightEdge, 324.0);
      expect(snackBarRightEdge, lessThan(344.0)); // Does not cross the separator
    });

    testWidgets(
        'Foldable screen (width 700) places snackbar inside right part when invoked from right',
        (tester) async {
      tester.view.physicalSize = const Size(700, 750);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      late BuildContext rightContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: Center(child: Text('Left Pane'))),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (ctx) {
                      rightContext = ctx;
                      return const Center(child: Text('Right Pane'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final margin = AppSnackBar.computeMargin(rightContext);
      // (700 + 12)/2 + 20 = 376
      expect(margin.left, 376.0);
      expect(margin.right, 20.0);
      expect(margin.bottom, 100.0);

      // Verify the snackbar bounds stay within the right half (356 to 700)
      final snackBarLeftEdge = margin.left;
      expect(snackBarLeftEdge, 376.0);
      expect(snackBarLeftEdge, greaterThan(356.0)); // Starts after the separator
    });

    testWidgets(
        'Dual-screen foldable with physical hinge places snackbar before or after hinge',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      tester.view.displayFeatures = const [
        DisplayFeature(
          bounds: Rect.fromLTRB(390, 0, 410, 600),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.unknown,
        ),
      ];
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDisplayFeatures);

      late BuildContext leftContext;
      late BuildContext rightContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 390,
                  child: Builder(
                    builder: (ctx) {
                      leftContext = ctx;
                      return const Center(child: Text('Left'));
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Builder(
                    builder: (ctx) {
                      rightContext = ctx;
                      return const Center(child: Text('Right'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Left part margin
      final leftMargin = AppSnackBar.computeMargin(leftContext);
      expect(leftMargin.left, 20.0);
      // 800 - 390 + 20 = 430
      expect(leftMargin.right, 430.0);
      expect(800 - leftMargin.right, 370.0); // 20dp before hinge at 390

      // Right part margin
      final rightMargin = AppSnackBar.computeMargin(rightContext);
      // 410 + 20 = 430
      expect(rightMargin.left, 430.0); // 20dp after hinge at 410
      expect(rightMargin.right, 20.0);
    });
  });
}
