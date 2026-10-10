import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState()) {
    _init();
  }

  final SettingsRepository _repository;

  void _init() {
    final settings = _repository.load();
    emit(
      SettingsState(
        themeMode: settings.themeMode,
        localeCode: settings.localeCode,
        favoriteSpotId: settings.favoriteSpotId,
      ),
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
}
