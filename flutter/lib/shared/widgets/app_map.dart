import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/context_ext.dart';

class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.onMapClick,
    this.onMapLongClick,
    this.onCameraMove,
    this.onCameraIdle,
    this.myLocationEnabled = false,
    this.compassEnabled = false,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.polygons = const <Polygon>{},
    this.circles = const <Circle>{},
    this.padding = EdgeInsets.zero,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
  });

  final CameraPosition initialCameraPosition;
  final void Function(GoogleMapController controller)? onMapCreated;
  final void Function(LatLng coordinates)? onMapClick;
  final void Function(LatLng coordinates)? onMapLongClick;
  final void Function(CameraPosition position)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final bool myLocationEnabled;
  final bool compassEnabled;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;
  final EdgeInsets padding;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  // Google Maps-inspired dark theme
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#202C3C"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#D4DCE5"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#202C3C"}, {"weight": 3}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#46566A"}, {"weight": 0.8}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#53657A"}, {"weight": 1.2}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#202C3C"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [{"color": "#17434D"}]
  },
  {
    "featureType": "landscape.natural.terrain",
    "elementType": "geometry",
    "stylers": [{"color": "#214D55"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#263447"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#C3CDD8"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#17434D"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#34465B"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#202C3C"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#C8D2DE"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#49647E"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#26364A"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#34465B"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#061633"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#79A9D4"}]
  }
]
''';

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    debugPrint('AppMap isDark: $isDark');

    return GoogleMap(
      key: ValueKey("GOOGLE_MAP_$isDark"),
      initialCameraPosition: initialCameraPosition,
      style: isDark ? _darkMapStyle : null,
      onMapCreated: onMapCreated,
      onTap: onMapClick,
      onLongPress: onMapLongClick,
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: false,
      compassEnabled: compassEnabled,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      zoomGesturesEnabled: zoomGesturesEnabled,
      scrollGesturesEnabled: scrollGesturesEnabled,
      rotateGesturesEnabled: rotateGesturesEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled,
      markers: markers,
      polylines: polylines,
      polygons: polygons,
      circles: circles,
      padding: padding,
      gestureRecognizers: gestureRecognizers,
    );
  }
}
