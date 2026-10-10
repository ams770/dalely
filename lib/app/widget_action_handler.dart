import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../shared/constants/storage_keys.dart';
import '../shared/cubits/car_proximity/car_proximity_cubit.dart';
import '../shared/cubits/location/location_cubit.dart';
import '../shared/cubits/spots/spots_cubit.dart';
import '../shared/services/home_widget_service.dart';
import '../shared/services/notification_service.dart';
import 'app_router.dart';

/// Handles widget and notification tap actions (e.g. `feen://park`, `feen://car`, `feen://spot/<id>`, `feen://found_car`).
class WidgetActionHandler {
  WidgetActionHandler({
    required this.navigatorKey,
    required this.homeWidgetService,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final HomeWidgetService homeWidgetService;

  StreamSubscription? _subscription;

  void init({NotificationService? notificationService}) {
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

    // Attach notification response listener
    notificationService?.init(onNotificationResponse: handleNotificationResponse);
  }

  void handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == NotificationService.actionFoundCar) {
      handleUri(
        Uri(scheme: StorageKeys.uriScheme, host: StorageKeys.uriFoundCar),
      );
      return;
    }
    if (response.actionId == NotificationService.actionOnMap) {
      handleUri(
        Uri(scheme: StorageKeys.uriScheme, host: StorageKeys.uriOnMap),
      );
      return;
    }

    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final uri = Uri.tryParse(payload);
      if (uri != null) {
        handleUri(uri);
      }
    }
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
    } else if (host == StorageKeys.uriCar || host == StorageKeys.uriOnMap) {
      final car = spotsCubit.state.car;
      if (car != null) {
        navigatorKey.currentState?.pushNamed(
          AppRouter.spotsMap,
          arguments: car.id,
        );
      }
    } else if (host == StorageKeys.uriFoundCar) {
      final proximityCubit = context.read<CarProximityCubit>();
      proximityCubit.onFoundCar();
      await spotsCubit.clearCar();
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
