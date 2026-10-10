import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.favoriteSpotId,
    this.hasCompletedOnboarding = false,
  });

  final ThemeMode themeMode;

  /// `null` means system / device language.
  final String? localeCode;

  final String? favoriteSpotId;

  final bool hasCompletedOnboarding;

  Locale? get locale {
    if (localeCode == null) return null;
    if (localeCode!.contains('_')) {
      final parts = localeCode!.split('_');
      return Locale(parts[0], parts[1]);
    }
    return Locale(localeCode!);
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    ValueGetter<String?>? localeCode,
    ValueGetter<String?>? favoriteSpotId,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode != null ? localeCode() : this.localeCode,
      favoriteSpotId:
          favoriteSpotId != null ? favoriteSpotId() : this.favoriteSpotId,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          other.themeMode == themeMode &&
          other.localeCode == localeCode &&
          other.favoriteSpotId == favoriteSpotId &&
          other.hasCompletedOnboarding == hasCompletedOnboarding;

  @override
  int get hashCode => Object.hash(
        themeMode,
        localeCode,
        favoriteSpotId,
        hasCompletedOnboarding,
      );
}
