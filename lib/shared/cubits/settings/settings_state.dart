import 'package:flutter/material.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.favoriteSpotId,
  });

  final ThemeMode themeMode;

  /// `null` means system / device language.
  final String? localeCode;

  final String? favoriteSpotId;

  Locale? get locale => localeCode != null ? Locale(localeCode!) : null;

  SettingsState copyWith({
    ThemeMode? themeMode,
    ValueGetter<String?>? localeCode,
    ValueGetter<String?>? favoriteSpotId,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode != null ? localeCode() : this.localeCode,
      favoriteSpotId:
          favoriteSpotId != null ? favoriteSpotId() : this.favoriteSpotId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          other.themeMode == themeMode &&
          other.localeCode == localeCode &&
          other.favoriteSpotId == favoriteSpotId;

  @override
  int get hashCode => Object.hash(themeMode, localeCode, favoriteSpotId);
}
