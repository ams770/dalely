import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:feen/app/feen_app.dart';
import 'package:feen/shared/l10n/generated/app_localizations.dart';

void main() {
  group('DalelyApp.resolveAppLocale', () {
    const supportedLocales = AppLocalizations.supportedLocales;

    group('User manual overrides', () {
      test('respects English user override even if device is Arabic', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: const Locale('en'),
          deviceLocale: const Locale('ar', 'EG'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });

      test('respects Arabic (EG) user override even if device is English', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: const Locale('ar', 'EG'),
          deviceLocale: const Locale('en', 'US'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('ar', 'EG'));
      });

      test('respects Arabic (SA) user override even if device is English', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: const Locale('ar', 'SA'),
          deviceLocale: const Locale('en', 'US'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('ar', 'SA'));
      });
    });

    group('Device locale resolution (no user override)', () {
      test('resolves to English when device language is English with Egypt region (en_EG)', () {
        // Previously this erroneously resolved to ar_EG due to countryCode == 'EG'
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('en', 'EG'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });

      test('resolves to English when device language is English (en_US)', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('en', 'US'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });

      test('resolves to English when device language is generic English (en)', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('en'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });

      test('resolves to Egyptian Arabic when device language is ar_EG', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('ar', 'EG'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('ar', 'EG'));
      });

      test('resolves to Saudi Arabic when device language is ar_SA', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('ar', 'SA'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('ar', 'SA'));
      });

      test('resolves to Gulf/Saudi Arabic when device country is in Gulf (e.g. ar_AE, ar_KW)', () {
        final ae = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('ar', 'AE'),
          supportedLocales: supportedLocales,
        );
        expect(ae, const Locale('ar', 'SA'));

        final kw = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('ar', 'KW'),
          supportedLocales: supportedLocales,
        );
        expect(kw, const Locale('ar', 'SA'));
      });

      test('resolves to Arabic fallback when device language is generic ar', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('ar'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('ar', 'EG'));
      });
    });

    group('Fallback to English on failure or unsupported device locales', () {
      test('falls back to English when device locale is French (fr_FR)', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('fr', 'FR'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });

      test('falls back to English when device locale is Spanish (es_ES)', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: const Locale('es', 'ES'),
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });

      test('falls back to English when device locale is null', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          deviceLocale: null,
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });
    });

    group('Preferred locales list resolution', () {
      test('resolves to English if secondary preferred language is English', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          preferredLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });

      test('resolves to Arabic if secondary preferred language is Arabic', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          preferredLocales: const [
            Locale('es', 'ES'),
            Locale('ar', 'EG'),
          ],
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('ar', 'EG'));
      });

      test('falls back to English if no preferred language is supported', () {
        final result = DalelyApp.resolveAppLocale(
          userOverride: null,
          preferredLocales: const [
            Locale('de', 'DE'),
            Locale('it', 'IT'),
          ],
          supportedLocales: supportedLocales,
        );
        expect(result, const Locale('en'));
      });
    });
  });
}
