import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/spot.dart';
import '../utils/spot_link_builder.dart';
import '../utils/spots_csv_builder.dart';

class ShareService {
  const ShareService();

  /// Shares a single spot text with map link.
  Future<void> shareSpot(
    Spot spot, {
    required AppLocalizations l10n,
    Rect? sharePositionOrigin,
  }) async {
    final text = SpotLinkBuilder.buildSingle(spot, l10n: l10n);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: spot.isCar ? l10n.myCar : spot.name,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Shares all spots formatted as a text list.
  Future<void> shareAllSpots(
    List<Spot> spots, {
    required AppLocalizations l10n,
    Rect? sharePositionOrigin,
  }) async {
    final text = SpotLinkBuilder.buildAll(spots, l10n: l10n);
    if (text.isEmpty) return;

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: l10n.shareSubject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Exports and shares all spots as a CSV spreadsheet (compatible with Microsoft Excel).
  Future<void> shareAllSpotsAsCsv(
    List<Spot> spots, {
    required AppLocalizations l10n,
    Rect? sharePositionOrigin,
  }) async {
    final bytes = SpotsCsvBuilder.buildBytes(spots, l10n: l10n);
    if (bytes.isEmpty) return;

    final file = XFile.fromData(
      bytes,
      mimeType: 'text/csv',
      name: 'dalely_spots.csv',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: ['dalely_spots.csv'],
        subject: l10n.exportSubject,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}

