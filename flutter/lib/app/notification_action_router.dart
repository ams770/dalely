import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../shared/constants/spot_categories.dart';
import '../shared/constants/storage_keys.dart';
import '../shared/cubits/car_proximity/car_proximity_cubit.dart';
import '../shared/cubits/car_tracking/car_tracking_cubit.dart';
import '../shared/cubits/location/location_cubit.dart';
import '../shared/cubits/spots/spots_cubit.dart';
import '../shared/models/spot.dart';
import '../shared/services/home_widget_service.dart';
import '../shared/services/notification_service.dart';
import '../shared/utils/geo_uri_parser.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'app_router.dart';

/// Central router for notification and widget actions ({SHOW_MAP, FOUND_CAR, DONE, PARK, CAR}).
///
/// Supports:
/// - Cold start initial intent/action via MethodChannel
/// - Warm start action events via EventChannel
/// - Offline/background action sync via SharedPreferences
/// - Home widget clicks via HomeWidgetService
/// - Local notifications response listener
/// - Automatic debounce & de-duplication
/// - Readiness waiting until Navigator and Blocs are mounted
class NotificationActionRouter {
  NotificationActionRouter({
    required this.navigatorKey,
    this.homeWidgetService = const HomeWidgetService(),
    this.methodChannel = const MethodChannel('feen/notification_actions'),
    this.eventChannel = const EventChannel('feen/notification_actions/events'),
    this.currentRouteGetter,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final HomeWidgetService homeWidgetService;
  final MethodChannel methodChannel;
  final EventChannel eventChannel;
  final String? Function()? currentRouteGetter;

  StreamSubscription? _eventSubscription;
  StreamSubscription? _widgetSubscription;
  AppLifecycleListener? _lifecycleListener;

  bool _initialized = false;
  String? _lastAction;
  int _lastActionTimestamp = 0;

  void init({NotificationService? notificationService}) {
    if (_initialized) return;
    _initialized = true;

    // 1. Listen for live action events from native layer (warm start / receiver)
    try {
      _eventSubscription = eventChannel.receiveBroadcastStream().listen((
        event,
      ) {
        if (event is Map) {
          final action = event['action'] as String?;
          final data = event['data'] as String?;
          final timestamp = (event['timestamp'] as num?)?.toInt();
          if (action != null) {
            handleAction(action: action, data: data, timestamp: timestamp);
          }
        }
      }, onError: (_) {});
    } catch (_) {}

    // 2. Query initial action (cold start)
    _queryInitialAction();

    // 3. Check pending action recorded by broadcast receiver while app was dead
    checkPendingActions();

    // 4. Hook lifecycle onResume to re-check pending actions when app returns to foreground
    _lifecycleListener = AppLifecycleListener(onResume: checkPendingActions);

    // 5. Home widget clicks
    _widgetSubscription = homeWidgetService.widgetClicked.listen((uri) {
      if (uri != null) {
        handleUri(uri);
      }
    });

    homeWidgetService.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        handleUri(uri);
      }
    });

    // 6. Local notifications
    NotificationService.setResponseListener(handleNotificationResponse);
  }

  Future<void> _queryInitialAction() async {
    try {
      final initial = await methodChannel.invokeMapMethod<String, dynamic>(
        'getInitialAction',
      );
      if (initial != null) {
        final action = initial['action'] as String?;
        final data = initial['data'] as String?;
        final timestamp = (initial['timestamp'] as num?)?.toInt();
        if (action != null) {
          await handleAction(action: action, data: data, timestamp: timestamp);
        }
      }
    } catch (_) {}
  }

  Future<void> checkPendingActions() async {
    try {
      final pending = await methodChannel.invokeMapMethod<String, dynamic>(
        'getPendingAction',
      );
      if (pending != null) {
        final action = pending['action'] as String?;
        final data = pending['data'] as String?;
        final timestamp = (pending['timestamp'] as num?)?.toInt();
        if (action != null) {
          await handleAction(action: action, data: data, timestamp: timestamp);
          await methodChannel.invokeMethod<void>('clearPendingAction');
        }
      }
    } catch (_) {}

    // Check pending spots saved while app was closed or in background
    await _syncPendingSavedSpots();
  }

  void handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == NotificationService.actionFoundCar) {
      handleAction(action: 'FOUND_CAR');
      return;
    }
    if (response.actionId == NotificationService.actionOnMap) {
      handleAction(action: 'SHOW_MAP');
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

  void handleUri(Uri uri) {
    if (uri.scheme == 'geo') {
      handleAction(action: 'OPEN_LOCATION', data: uri.toString());
      return;
    }
    if (uri.scheme != StorageKeys.uriScheme &&
        uri.scheme != StorageKeys.uriSchemeDalely) {
      return;
    }
    final host = uri.host;
    if (host == 'save' || host == 'add') {
      handleAction(action: 'OPEN_LOCATION', data: uri.toString());
    } else if (host == 'map' ||
        host == StorageKeys.uriCar ||
        host == StorageKeys.uriOnMap) {
      final spotParam = uri.queryParameters['spot'];
      handleAction(action: 'SHOW_MAP', data: spotParam ?? 'car');
    } else if (host == StorageKeys.uriFoundCar ||
        host == 'found_car' ||
        host == 'done') {
      handleAction(action: 'FOUND_CAR');
    } else if (host == StorageKeys.uriPark) {
      handleAction(action: 'PARK');
    } else if (host == StorageKeys.uriSpot) {
      final spotId = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : null;
      handleAction(action: 'SHOW_SPOT', data: spotId);
    }
  }

  Future<void> handleAction({
    required String action,
    String? data,
    int? timestamp,
    int attempt = 0,
  }) async {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    // Idempotency / de-duplication: Ignore duplicate actions fired within 1500 ms
    if (_lastAction == action && (now - _lastActionTimestamp).abs() < 1500) {
      return;
    }

    // Wait until navigator and widget tree are fully mounted
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      if (attempt < 15) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return handleAction(
          action: action,
          data: data,
          timestamp: timestamp,
          attempt: attempt + 1,
        );
      }
      return;
    }

    _lastAction = action;
    _lastActionTimestamp = now;

    switch (action) {
      case 'SHOW_MAP':
        final spotsCubit = context.read<SpotsCubit>();
        final car = spotsCubit.state.car;
        final targetSpotId = data ?? car?.id ?? 'car';

        // Check if map route with car is already the top route
        var isAlreadyOnMap = false;
        if (currentRouteGetter != null) {
          final top = currentRouteGetter!();
          if (top == AppRouter.spotsMap || top == AppRouter.map) {
            isAlreadyOnMap = true;
          }
        } else {
          navigatorKey.currentState?.popUntil((route) {
            if (route.settings.name == AppRouter.spotsMap ||
                route.settings.name == AppRouter.map) {
              if (route.settings.arguments == targetSpotId ||
                  route.settings.arguments == 'car' ||
                  route.settings.arguments == null) {
                isAlreadyOnMap = true;
              }
            }
            return true; // do not actually pop
          });
        }

        if (isAlreadyOnMap) {
          return;
        }

        // Navigate single-instance to spotsMap
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.spotsMap,
          (route) => route.isFirst,
          arguments: targetSpotId,
        );
        break;

      case 'FOUND_CAR':
      case 'DONE':
        final proximityCubit = context.read<CarProximityCubit>();
        final trackingCubit = context.read<CarTrackingCubit>();
        final spotsCubit = context.read<SpotsCubit>();
        proximityCubit.onFoundCar();
        await trackingCubit.stopCarTracking();
        await spotsCubit.clearCar();
        try {
          await methodChannel.invokeMethod<void>('clearPendingAction');
        } catch (_) {}
        break;

      case 'PARK':
        final trackingCubit = context.read<CarTrackingCubit>();
        final locationCubit = context.read<LocationCubit>();
        final spotsCubit = context.read<SpotsCubit>();
        await trackingCubit.stopCarTracking();
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
        break;

      case 'CAR':
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouter.spotsMap,
          (route) => route.isFirst,
          arguments: 'car',
        );
        break;

      case 'SHOW_SPOT':
        if (data != null && data.isNotEmpty) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRouter.spotsMap,
            (route) => route.isFirst,
            arguments: data,
          );
        }
        break;

      case 'OPEN_LOCATION':
        if (data != null && data.isNotEmpty) {
          final currentLocation = context.read<LocationCubit>().state.latLng;
          final parsed = await GeoUriParser.parseAsync(data);
          if (!context.mounted) return;

          LatLng? target;
          String? name;
          if (parsed != null) {
            target = LatLng(parsed.latitude, parsed.longitude);
            name = parsed.label ?? GeoUriParser.extractLabel(data);
          } else {
            name = GeoUriParser.extractLabel(data);
          }

          target ??= currentLocation;

          navigatorKey.currentState?.pushNamed(
            AppRouter.saveSpot,
            arguments: SaveSpotArgs(target: target, name: name),
          );
        }
        break;

      case 'SPOT_SAVED':
        if (data != null && data.isNotEmpty) {
          final spotsCubit = context.read<SpotsCubit>();
          await _saveSpotFromJson(spotsCubit, data);
        }
        break;
    }
  }

  Future<void> _syncPendingSavedSpots() async {
    try {
      final list = await methodChannel.invokeListMethod<String>(
        'getPendingSavedSpots',
      );
      if (list != null && list.isNotEmpty) {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final spotsCubit = context.read<SpotsCubit>();
          for (final jsonStr in list) {
            await _saveSpotFromJson(spotsCubit, jsonStr);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSpotFromJson(SpotsCubit spotsCubit, String jsonStr) async {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final id = map['id'] as String;
      final name = map['name'] as String;
      final catName = map['category'] as String?;
      final category = SpotCategory.fromName(catName);
      final lat = (map['latitude'] as num).toDouble();
      final lng = (map['longitude'] as num).toDouble();
      final savedAtMs = map['savedAt'] as int?;
      final savedAt = savedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(savedAtMs)
          : DateTime.now();

      final spot = Spot(
        id: id,
        name: name,
        category: category,
        latitude: lat,
        longitude: lng,
        savedAt: savedAt,
        status: SpotStatus.none,
      );
      await spotsCubit.spotsRepository.save(spot);
    } catch (_) {}
  }

  void dispose() {
    _eventSubscription?.cancel();
    _widgetSubscription?.cancel();
    _lifecycleListener?.dispose();
  }
}
