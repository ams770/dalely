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
  static const String map = '/map';
  static const String saveSpot = '/save-spot';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    final path = uri?.path ?? settings.name;

    switch (path) {
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

      case map:
      case spotsMap:
        final spotFromArg = settings.arguments as String?;
        final spotFromQuery = uri?.queryParameters['spot'];
        final initialSpotId = spotFromArg ?? spotFromQuery;
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
