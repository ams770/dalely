import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../app_settings.dart';

/// Hand-written adapter for [AppSettings]. Type id `1` is permanent.
///
/// Layout: field count, then fields in this exact order (append-only).
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  static const int _fieldCount = 3;

  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final count = reader.readByte();
    final themeName = reader.readString();
    final localeCode = reader.read() as String?;
    final favoriteSpotId = reader.read() as String?;
    for (var i = _fieldCount; i < count; i++) {
      reader.read();
    }
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      localeCode: localeCode,
      favoriteSpotId: favoriteSpotId,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(_fieldCount)
      ..writeString(obj.themeMode.name)
      ..write(obj.localeCode)
      ..write(obj.favoriteSpotId);
  }
}
