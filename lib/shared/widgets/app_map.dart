import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../theme/map_styles.dart';
import '../utils/context_ext.dart';

/// A wrapper around [MapLibreMap] applying Dalely's CARTO vector tile styling,
/// gesture defaults, and theme integration.
class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.onStyleLoadedCallback,
    this.onMapClick,
    this.onMapLongClick,
    this.onCameraMove,
    this.onCameraIdle,
    this.trackCameraPosition = true,
    this.myLocationEnabled = false,
    this.compassEnabled = false,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.doubleClickZoomEnabled = true,
    this.dragEnabled = true,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
  });

  final CameraPosition initialCameraPosition;
  final void Function(MapLibreMapController controller)? onMapCreated;
  final VoidCallback? onStyleLoadedCallback;
  final void Function(Point<double> point, LatLng coordinates)? onMapClick;
  final void Function(Point<double> point, LatLng coordinates)? onMapLongClick;
  final void Function(CameraPosition position)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final bool trackCameraPosition;
  final bool myLocationEnabled;
  final bool compassEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool doubleClickZoomEnabled;
  final bool dragEnabled;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return const SizedBox.expand();
    }

    final isDark = context.isDarkMode;
    final styleString = isDark ? MapStyles.dark : MapStyles.light;

    return MapLibreMap(
      key: ValueKey('maplibre_${isDark ? "dark" : "light"}'),
      styleString: styleString,
      initialCameraPosition: initialCameraPosition,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: onStyleLoadedCallback,
      onMapClick: onMapClick,
      onMapLongClick: onMapLongClick,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      trackCameraPosition: trackCameraPosition,
      myLocationEnabled: myLocationEnabled,
      compassEnabled: compassEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled,
      scrollGesturesEnabled: scrollGesturesEnabled,
      rotateGesturesEnabled: rotateGesturesEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled,
      doubleClickZoomEnabled: doubleClickZoomEnabled,
      dragEnabled: dragEnabled,
      gestureRecognizers: gestureRecognizers,
      attributionButtonPosition: AttributionButtonPosition.bottomRight,
      logoEnabled: false,
    );
  }
}

/// Backward compatibility alias for [AppMap].
typedef AppGoogleMap = AppMap;
