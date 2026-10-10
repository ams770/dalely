import 'package:flutter/material.dart';

/// Persisted user preferences.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.favoriteSpotId,
  });

  final ThemeMode themeMode;

  /// `null` means "follow the device language".
  final String? localeCode;

  /// Spot shown on the "favorite" native widget.
  final String? favoriteSpotId;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ValueGetter<String?>? localeCode,
    ValueGetter<String?>? favoriteSpotId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode != null ? localeCode() : this.localeCode,
      favoriteSpotId:
          favoriteSpotId != null ? favoriteSpotId() : this.favoriteSpotId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.themeMode == themeMode &&
          other.localeCode == localeCode &&
          other.favoriteSpotId == favoriteSpotId;

  @override
  int get hashCode => Object.hash(themeMode, localeCode, favoriteSpotId);
}
