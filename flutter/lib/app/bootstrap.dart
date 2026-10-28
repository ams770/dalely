import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../shared/constants/spot_categories.dart';
import '../shared/constants/storage_keys.dart';
import '../shared/data/settings_repository.dart';
import '../shared/data/spots_repository.dart';
import '../shared/models/adapters/app_settings_adapter.dart';
import '../shared/models/adapters/spot_adapter.dart';
import '../shared/models/app_settings.dart';
import '../shared/models/spot.dart';
import '../shared/services/car_tracking_service.dart';
import '../shared/services/heading_service.dart';
import '../shared/services/home_widget_service.dart';
import '../shared/services/location_service.dart';
import '../shared/services/notification_service.dart';
import 'feen_app.dart';
import 'notification_action_router.dart';

class BootstrapDependencies {
  const BootstrapDependencies({
    required this.spotsRepository,
    required this.settingsRepository,
    required this.locationService,
    required this.headingService,
    required this.homeWidgetService,
    required this.notificationService,
    required this.carTrackingService,
    required this.actionRouter,
  });

  final SpotsRepository spotsRepository;
  final SettingsRepository settingsRepository;
  final LocationService locationService;
  final HeadingService headingService;
  final HomeWidgetService homeWidgetService;
  final NotificationService notificationService;
  final CarTrackingService carTrackingService;
  final NotificationActionRouter actionRouter;
}

Future<BootstrapDependencies> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarDividerColor: Color(0x00000000),
      systemNavigationBarContrastEnforced: false,
    ),
  );

  await SystemChrome.setPreferredOrientations([]);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Type Adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SpotAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }

  // Open Boxes
  final spotsBox = await Hive.openBox<Spot>(StorageKeys.spotsBox);

  // Drain any pending spots saved natively before Flutter started
  try {
    const channel = MethodChannel('feen/notification_actions');
    final pendingSpots =
        await channel.invokeListMethod<String>('getPendingSavedSpots');
    if (pendingSpots != null && pendingSpots.isNotEmpty) {
      for (final jsonStr in pendingSpots) {
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
        );
        await spotsBox.put(spot.id, spot);
      }
    }
  } catch (_) {}

  Box<AppSettings> settingsBox;
  try {
    settingsBox = await Hive.openBox<AppSettings>(StorageKeys.settingsBox);
  } catch (_) {
    await Hive.deleteBoxFromDisk(StorageKeys.settingsBox);
    settingsBox = await Hive.openBox<AppSettings>(StorageKeys.settingsBox);
  }

  // Initialize HomeWidget
  const homeWidgetService = HomeWidgetService();
  await homeWidgetService.init();

  // Initialize Notifications
  const notificationService = NotificationService();
  await notificationService.init();

  const locationService = LocationService();
  final headingService = HeadingService();
  final carTrackingService = PlatformCarTrackingService();
  final actionRouter = NotificationActionRouter(
    navigatorKey: appNavigatorKey,
    homeWidgetService: homeWidgetService,
    currentRouteGetter: () => appRouteObserver.currentRoute,
  );

  return BootstrapDependencies(
    spotsRepository: SpotsRepository(spotsBox),
    settingsRepository: SettingsRepository(settingsBox),
    locationService: locationService,
    headingService: headingService,
    homeWidgetService: homeWidgetService,
    notificationService: notificationService,
    carTrackingService: carTrackingService,
    actionRouter: actionRouter,
  );
}
