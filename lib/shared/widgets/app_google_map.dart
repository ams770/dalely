import '../theme/map_styles.dart';
import '../utils/context_ext.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A wrapper around [GoogleMap] applying Dalely's custom map styling,
/// gesture defaults, and theme integration.
class AppGoogleMap extends StatelessWidget {
  const AppGoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.onTap,
    this.onCameraMove,
    this.onCameraIdle,
    this.onCameraMoveStarted,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.compassEnabled = false,
    this.mapToolbarEnabled = false,
    this.liteModeEnabled = false,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.padding = EdgeInsets.zero,
  });

  final CameraPosition initialCameraPosition;
  final MapCreatedCallback? onMapCreated;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final ArgumentCallback<LatLng>? onTap;
  final CameraPositionCallback? onCameraMove;
  final VoidCallback? onCameraIdle;
  final VoidCallback? onCameraMoveStarted;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool compassEnabled;
  final bool mapToolbarEnabled;
  final bool liteModeEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      onMapCreated: onMapCreated,
      markers: markers,
      polylines: polylines,
      circles: circles,
      onTap: onTap,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      onCameraMoveStarted: onCameraMoveStarted,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      compassEnabled: compassEnabled,
      mapToolbarEnabled: mapToolbarEnabled,
      liteModeEnabled: liteModeEnabled,
      zoomGesturesEnabled: liteModeEnabled ? false : zoomGesturesEnabled,
      scrollGesturesEnabled: liteModeEnabled ? false : scrollGesturesEnabled,
      rotateGesturesEnabled: liteModeEnabled ? false : rotateGesturesEnabled,
      tiltGesturesEnabled: liteModeEnabled ? false : tiltGesturesEnabled,
      gestureRecognizers: gestureRecognizers,
      padding: padding,
      style: context.isDarkMode ? MapStyles.dark : null,
    );
  }
}
