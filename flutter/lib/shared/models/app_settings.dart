import 'package:flutter/material.dart';

/// Persisted user preferences.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.favoriteSpotId,
    this.hasCompletedOnboarding = false,
    this.carDistanceNotificationEnabled = true,
  });

  final ThemeMode themeMode;

  /// `null` means "follow the device language".
  final String? localeCode;

  /// Spot shown on the "favorite" native widget.
  final String? favoriteSpotId;

  /// Whether the user has completed or skipped the onboarding flow.
  final bool hasCompletedOnboarding;

  /// Whether to show the pinned car distance notification / Live Activity when heading to car.
  final bool carDistanceNotificationEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ValueGetter<String?>? localeCode,
    ValueGetter<String?>? favoriteSpotId,
    bool? hasCompletedOnboarding,
    bool? carDistanceNotificationEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode != null ? localeCode() : this.localeCode,
      favoriteSpotId:
          favoriteSpotId != null ? favoriteSpotId() : this.favoriteSpotId,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      carDistanceNotificationEnabled:
          carDistanceNotificationEnabled ?? this.carDistanceNotificationEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.themeMode == themeMode &&
          other.localeCode == localeCode &&
          other.favoriteSpotId == favoriteSpotId &&
          other.hasCompletedOnboarding == hasCompletedOnboarding &&
          other.carDistanceNotificationEnabled == carDistanceNotificationEnabled;

  @override
  int get hashCode => Object.hash(
        themeMode,
        localeCode,
        favoriteSpotId,
        hasCompletedOnboarding,
        carDistanceNotificationEnabled,
      );
}
