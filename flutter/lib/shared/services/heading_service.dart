import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';

class HeadingService {
  HeadingService({
    this.minDeltaDegrees = 3.0,
    @visibleForTesting this.customStream,
  });

  static const EventChannel _androidCompassChannel =
      EventChannel('feen/compass');

  final double minDeltaDegrees;
  final Stream<double>? customStream;

  Stream<double>? get events {
    if (customStream != null) {
      return _filterStream(customStream!);
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final stream = _androidCompassChannel
            .receiveBroadcastStream()
            .where((event) => event != null)
            .map((event) => ((event as num).toDouble() % 360.0 + 360.0) % 360.0);
        return _filterStream(stream);
      } catch (_) {
        // Fallback to flutter_compass if channel registration fails
      }
    }

    final compassEvents = FlutterCompass.events;
    if (compassEvents == null) return null;

    final stream = compassEvents
        .where((event) => event.heading != null)
        .map((event) => (event.heading! % 360.0 + 360.0) % 360.0);

    return _filterStream(stream);
  }

  Stream<double> _filterStream(Stream<double> rawStream) {
    double? lastHeading;
    return rawStream.where((heading) {
      if (lastHeading == null) {
        lastHeading = heading;
        return true;
      }
      final diff = (heading - lastHeading!).abs();
      final normalizedDiff = diff > 180.0 ? 360.0 - diff : diff;
      if (normalizedDiff >= minDeltaDegrees) {
        lastHeading = heading;
        return true;
      }
      return false;
    });
  }
}
