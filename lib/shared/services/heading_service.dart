import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

class HeadingService {
  HeadingService({this.minDeltaDegrees = 3.0});

  final double minDeltaDegrees;
  double? _lastHeading;

  Stream<double>? get events {
    final stream = FlutterCompass.events;
    if (stream == null) return null;

    return stream
        .where((event) => event.heading != null)
        .map((event) => (event.heading! % 360 + 360) % 360)
        .where((heading) {
          if (_lastHeading == null) {
            _lastHeading = heading;
            return true;
          }
          final diff = (heading - _lastHeading!).abs();
          final normalizedDiff = diff > 180 ? 360 - diff : diff;
          if (normalizedDiff >= minDeltaDegrees) {
            _lastHeading = heading;
            return true;
          }
          return false;
        });
  }
}
