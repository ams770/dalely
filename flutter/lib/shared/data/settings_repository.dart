import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../constants/storage_keys.dart';
import '../models/app_settings.dart';

/// The only place that reads/writes the settings box.
///
/// Every update re-reads the stored record so independent writers
/// (theme, language, favorite spot) never overwrite each other.
class SettingsRepository {
  const SettingsRepository(this._box);

  final Box<AppSettings> _box;

  AppSettings load() =>
      _box.get(StorageKeys.settingsRecord) ?? const AppSettings();

  Future<AppSettings> setThemeMode(ThemeMode mode) =>
      _update(load().copyWith(themeMode: mode));

  Future<AppSettings> setLocaleCode(String? code) =>
      _update(load().copyWith(localeCode: () => code));

  Future<AppSettings> setFavoriteSpotId(String? id) =>
      _update(load().copyWith(favoriteSpotId: () => id));

  Future<AppSettings> setHasCompletedOnboarding(bool completed) =>
      _update(load().copyWith(hasCompletedOnboarding: completed));

  Future<AppSettings> setCarDistanceNotificationEnabled(bool enabled) =>
      _update(load().copyWith(carDistanceNotificationEnabled: enabled));

  Future<AppSettings> _update(AppSettings settings) async {
    await _box.put(StorageKeys.settingsRecord, settings);
    return settings;
  }
}
