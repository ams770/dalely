import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(_computeInitialState(_repository));

  final SettingsRepository _repository;

  static SettingsState _computeInitialState(SettingsRepository repository) {
    final settings = repository.load();
    return SettingsState(
      themeMode: settings.themeMode,
      localeCode: settings.localeCode,
      favoriteSpotId: settings.favoriteSpotId,
      hasCompletedOnboarding: settings.hasCompletedOnboarding,
      carDistanceNotificationEnabled:
          settings.carDistanceNotificationEnabled,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final updated = await _repository.setThemeMode(mode);
    if (isClosed) return;
    emit(state.copyWith(themeMode: updated.themeMode));
  }

  Future<void> setLocaleCode(String? localeCode) async {
    final updated = await _repository.setLocaleCode(localeCode);
    if (isClosed) return;
    emit(state.copyWith(localeCode: () => updated.localeCode));
  }

  Future<void> setFavoriteSpotId(String? spotId) async {
    final updated = await _repository.setFavoriteSpotId(spotId);
    if (isClosed) return;
    emit(state.copyWith(favoriteSpotId: () => updated.favoriteSpotId));
  }

  Future<void> completeOnboarding() async {
    final updated = await _repository.setHasCompletedOnboarding(true);
    if (isClosed) return;
    emit(state.copyWith(hasCompletedOnboarding: updated.hasCompletedOnboarding));
  }

  Future<void> setCarDistanceNotificationEnabled(bool enabled) async {
    final updated = await _repository.setCarDistanceNotificationEnabled(enabled);
    if (isClosed) return;
    emit(
      state.copyWith(
        carDistanceNotificationEnabled:
            updated.carDistanceNotificationEnabled,
      ),
    );
  }
}
