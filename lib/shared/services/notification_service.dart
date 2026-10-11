import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_assets.dart';

/// Service responsible for managing local notifications, such as the
/// pinned parking status notification showing the timer and live distance.
class NotificationService {
  const NotificationService();

  static const int parkingNotificationId = 1001;
  static const String parkingChannelId = 'parking_status';
  static const String parkingChannelName = 'Car Parking Status';
  static const String parkingChannelDescription =
      'Shows parking elapsed timer and distance to your parked car.';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static Uint8List? _cachedCarIconBytes;

  static DidReceiveNotificationResponseCallback? _responseListener;
  static NotificationResponse? _pendingResponse;

  /// Registers the handler for notification and action-button taps.
  /// A tap that launched the app before the handler existed is delivered now.
  static void setResponseListener(DidReceiveNotificationResponseCallback? l) {
    _responseListener = l;
    final pending = _pendingResponse;
    if (l != null && pending != null) {
      _pendingResponse = null;
      l(pending);
    }
  }

  static void _dispatchResponse(NotificationResponse response) {
    final listener = _responseListener;
    if (listener == null) {
      _pendingResponse = response;
    } else {
      listener(response);
    }
  }

  /// Initializes the local notifications plugin and preloads the car icon.
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'parking_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              actionOnMap,
              'On map',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              actionFoundCar,
              'Found my car',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
        DarwinNotificationCategory(
          'arrival_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              actionOnMap,
              'On map',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              actionFoundCar,
              'Found my car',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _dispatchResponse,
    );

    _isInitialized = true;
    unawaited(_preloadCarIcon());
  }

  static Future<Uint8List?> _preloadCarIcon() async {
    if (_cachedCarIconBytes != null) return _cachedCarIconBytes;
    try {
      final data = await rootBundle.load(AssetProvider.car);
      _cachedCarIconBytes = data.buffer.asUint8List();
    } catch (e) {
      debugPrint('NotificationService: Could not load car asset: $e');
    }
    return _cachedCarIconBytes;
  }

  /// Requests notification permissions on Android (13+) and iOS.
  Future<bool> requestPermission() async {
    bool? granted = false;

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      granted = await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImplementation != null) {
      granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted ?? false;
  }

  /// Shows or updates the ongoing/pinned parking notification.
  ///
  /// Legacy local notification (ID 1001) is cancelled in favor of the new
  /// [CarTrackingService] (Live Activity on iOS & ongoing foreground service on Android).
  Future<void> showParkingNotification({
    required DateTime savedAt,
    required String title,
    required String distanceText,
    bool showBannerOnIos = false,
  }) async {
    await cancelParkingNotification();
  }

  /// ID and channel for arrival proximity notifications.
  static const int arrivalNotificationId = 1002;
  static const String arrivalChannelId = 'car_arrival';
  static const String arrivalChannelName = 'Car Arrival Alerts';
  static const String arrivalChannelDescription =
      'Alerts when you return to your parked car with quick actions.';

  /// Action IDs for arrival notification buttons.
  static const String actionOnMap = 'action_on_map';
  static const String actionFoundCar = 'action_found_car';

  /// Shows the high-priority arrival notification when user is <= 5m from car.
  /// Includes action buttons matching the car card ("On map" and "Found my car").
  Future<void> showCarArrivalNotification({
    required String title,
    required String body,
    required String onMapActionLabel,
    required String foundCarActionLabel,
  }) async {
    if (!_isInitialized) return;
    try {
      final carBytes = _cachedCarIconBytes ?? await _preloadCarIcon();
      final androidBitmap = carBytes != null
          ? ByteArrayAndroidBitmap(carBytes)
          : null;

      final androidDetails = AndroidNotificationDetails(
        arrivalChannelId,
        arrivalChannelName,
        channelDescription: arrivalChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: title,
        colorized: true,
        color: const Color(0xFFFF6B4A),
        icon: '@mipmap/ic_launcher',
        largeIcon: androidBitmap,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Feen • Car Arrival',
        ),
        category: AndroidNotificationCategory.recommendation,
        visibility: NotificationVisibility.public,
        subText: 'Feen Live',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionFoundCar,
            '✅ $foundCarActionLabel',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            actionOnMap,
            '🗺️ $onMapActionLabel',
            showsUserInterface: true,
          ),
        ],
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
        subtitle: title,
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'feen_parking',
        categoryIdentifier: 'arrival_category',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        arrivalNotificationId,
        title,
        body,
        notificationDetails,
        payload: 'feen://car',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to show arrival notification: $e',
      );
    }
  }

  /// Cancels the arrival notification.
  Future<void> cancelArrivalNotification() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancel(arrivalNotificationId);
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to cancel arrival notification: $e',
      );
    }
  }

  /// Cancels the ongoing parking notification when the car is found or cleared.
  Future<void> cancelParkingNotification() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancel(parkingNotificationId);
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to cancel parking notification: $e',
      );
    }
  }
}
