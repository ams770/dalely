import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../shared/constants/storage_keys.dart';
import '../shared/cubits/location/location_cubit.dart';
import '../shared/cubits/spots/spots_cubit.dart';
import '../shared/services/home_widget_service.dart';
import '../shared/services/maps_launcher.dart';
import 'app_router.dart';

/// Handles widget tap URIs (e.g. `feen://park`, `feen://car`, `feen://spot/<id>`).
class WidgetActionHandler {
  WidgetActionHandler({
    required this.navigatorKey,
    required this.homeWidgetService,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final HomeWidgetService homeWidgetService;

  StreamSubscription? _subscription;

  void init() {
    // Check if launched from a widget
    homeWidgetService.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        handleUri(uri);
      }
    });

    // Listen to incoming clicks while running
    _subscription = homeWidgetService.widgetClicked.listen((uri) {
      if (uri != null) {
        handleUri(uri);
      }
    });
  }

  void handleUri(Uri uri) async {
    if (uri.scheme != StorageKeys.uriScheme) return;

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final host = uri.host;
    final spotsCubit = context.read<SpotsCubit>();
    final locationCubit = context.read<LocationCubit>();

    if (host == StorageKeys.uriPark) {
      var pos = locationCubit.state.latLng;
      if (pos == null) {
        await locationCubit.requestPermission();
        pos = locationCubit.state.latLng;
      }
      if (pos != null) {
        await spotsCubit.parkCar(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    } else if (host == StorageKeys.uriCar) {
      final car = spotsCubit.state.car;
      if (car != null) {
        const MapsLauncher().openDirections(
          latitude: car.latitude,
          longitude: car.longitude,
        );
      }
    } else if (host == StorageKeys.uriSpot) {
      final spotId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (spotId != null) {
        navigatorKey.currentState?.pushNamed(
          AppRouter.spotsMap,
          arguments: spotId,
        );
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
