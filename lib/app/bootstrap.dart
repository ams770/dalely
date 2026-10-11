import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

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

  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  if (view != null && view.devicePixelRatio > 0) {
    final widthDp = view.physicalSize.width / view.devicePixelRatio;
    if (widthDp < 600) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

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
