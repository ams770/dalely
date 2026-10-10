import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../shared/constants/storage_keys.dart';
import '../shared/data/settings_repository.dart';
import '../shared/data/spots_repository.dart';
import '../shared/models/adapters/app_settings_adapter.dart';
import '../shared/models/adapters/spot_adapter.dart';
import '../shared/models/app_settings.dart';
import '../shared/models/spot.dart';
import '../shared/services/heading_service.dart';
import '../shared/services/home_widget_service.dart';
import '../shared/services/location_service.dart';

class BootstrapDependencies {
  const BootstrapDependencies({
    required this.spotsRepository,
    required this.settingsRepository,
    required this.locationService,
    required this.headingService,
    required this.homeWidgetService,
  });

  final SpotsRepository spotsRepository;
  final SettingsRepository settingsRepository;
  final LocationService locationService;
  final HeadingService headingService;
  final HomeWidgetService homeWidgetService;
}

Future<BootstrapDependencies> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final settingsBox = await Hive.openBox<AppSettings>(StorageKeys.settingsBox);

  // Initialize HomeWidget
  const homeWidgetService = HomeWidgetService();
  await homeWidgetService.init();

  const locationService = LocationService();
  final headingService = HeadingService();

  return BootstrapDependencies(
    spotsRepository: SpotsRepository(spotsBox),
    settingsRepository: SettingsRepository(settingsBox),
    locationService: locationService,
    headingService: headingService,
    homeWidgetService: homeWidgetService,
  );
}
