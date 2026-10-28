import 'package:feen/modules/settings/widgets/theme_mode_selector.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';
import 'package:feen/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeModeSelector Tests', () {
    testWidgets('Renders all 3 theme cards (System, Light, Dark)',
        (tester) async {
      ThemeMode selectedMode = ThemeMode.system;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: ThemeModeSelector(
                currentMode: selectedMode,
                onModeChanged: (mode) => selectedMode = mode,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.brightness_auto_rounded), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('Tapping Light card invokes onModeChanged(ThemeMode.light)',
        (tester) async {
      ThemeMode? tappedMode;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: ThemeModeSelector(
                currentMode: ThemeMode.system,
                onModeChanged: (mode) => tappedMode = mode,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(tappedMode, ThemeMode.light);
    });

    testWidgets('Tapping Dark card invokes onModeChanged(ThemeMode.dark)',
        (tester) async {
      ThemeMode? tappedMode;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: ThemeModeSelector(
                currentMode: ThemeMode.light,
                onModeChanged: (mode) => tappedMode = mode,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(tappedMode, ThemeMode.dark);
    });

    testWidgets('Renders properly in Arabic RTL locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: ThemeModeSelector(
                currentMode: ThemeMode.system,
                onModeChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.brightness_auto_rounded), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    });
  });
}
