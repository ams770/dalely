import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme_extension.dart';

extension ContextExtensions on BuildContext {
  /// Convenient accessor for localized strings.
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Custom theme tokens.
  AppThemeExtension get tokens =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.light;

  /// Shorthand for active ThemeData.
  ThemeData get theme => Theme.of(this);

  /// ColorScheme shortcut.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// TextTheme shortcut.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Check if the layout direction is right-to-left.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
