import 'package:flutter/material.dart';

import '../modules/home/home_screen.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/save_spot/save_spot_screen.dart';
import '../modules/settings/settings_screen.dart';
import '../modules/spots_map/spots_map_screen.dart';

abstract final class AppRouter {
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String spotsMap = '/spots-map';
  static const String saveSpot = '/save-spot';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case spotsMap:
        final initialSpotId = settings.arguments as String?;
        return MaterialPageRoute<void>(
          builder: (_) => SpotsMapScreen(initialSpotId: initialSpotId),
          settings: settings,
        );

      case saveSpot:
        return MaterialPageRoute<void>(
          builder: (_) => const SaveSpotScreen(),
          settings: settings,
        );

      case AppRouter.settings:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
    }
  }
}
