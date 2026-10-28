import 'dart:convert';
import 'dart:typed_data';

import '../l10n/generated/app_localizations.dart';
import '../models/spot.dart';
import 'spot_link_builder.dart';

abstract final class SpotsCsvBuilder {
  /// Header row containing column titles required for spreadsheet exports.
  static const List<String> headers = [
    'Name',
    'Latitude',
    'Longitude',
    'Google Maps URL',
  ];

  /// Escapes CSV values adhering to RFC 4180 rules.
  static String escapeCsvCell(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Builds a CSV formatted string from the provided list of spots.
  /// If the parked car is present, it is ordered first, followed by spots sorted newest first.
  static String build(List<Spot> spots, {required AppLocalizations l10n}) {
    if (spots.isEmpty) return '';

    final ordered = List<Spot>.from(spots)
      ..sort((a, b) {
        if (a.isCar) return -1;
        if (b.isCar) return 1;
        return b.savedAt.compareTo(a.savedAt);
      });

    final buffer = StringBuffer();
    buffer.write(headers.map(escapeCsvCell).join(','));
    buffer.write('\r\n');

    for (final spot in ordered) {
      final displayName = spot.isCar
          ? (spot.name.trim().isEmpty ? l10n.myCar : spot.name)
          : spot.name;
      final mapUrl = SpotLinkBuilder.mapUrl(
        latitude: spot.latitude,
        longitude: spot.longitude,
      );

      final row = [
        escapeCsvCell(displayName),
        spot.latitude.toString(),
        spot.longitude.toString(),
        escapeCsvCell(mapUrl),
      ];
      buffer.write(row.join(','));
      buffer.write('\r\n');
    }

    return buffer.toString();
  }

  /// Encodes the CSV string into UTF-8 bytes with a prepended UTF-8 BOM (`\uFEFF`).
  /// The UTF-8 BOM is required by Microsoft Excel on Windows/macOS to properly
  /// recognize UTF-8 Unicode characters (e.g. Arabic spot names) upon opening.
  static Uint8List buildBytes(
    List<Spot> spots, {
    required AppLocalizations l10n,
  }) {
    final csvString = build(spots, l10n: l10n);
    if (csvString.isEmpty) return Uint8List(0);
    return Uint8List.fromList(utf8.encode('\uFEFF$csvString'));
  }
}
