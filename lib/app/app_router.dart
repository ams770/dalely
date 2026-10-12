import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../modules/home/home_screen.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/search/search_spots_screen.dart';
import '../modules/settings/settings_screen.dart';
import '../modules/spots_map/cubit/spots_map_state.dart';
import '../modules/spots_map/spots_map_screen.dart';
import '../shared/utils/geo_uri_parser.dart';

class SaveSpotArgs {
  const SaveSpotArgs({this.target, this.name});
  final LatLng? target;
  final String? name;
}

abstract final class AppRouter {
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String spotsMap = '/spots-map';
  static const String map = '/map';
  static const String saveSpot = '/save-spot';
  static const String search = '/search';
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
        LatLng? initialTarget;
        String? initialSpotName;
        final args = settings.arguments;
        if (args is SaveSpotArgs) {
          initialTarget = args.target;
          initialSpotName = args.name;
        } else if (args is LatLng) {
          initialTarget = args;
        } else if (uri != null && uri.queryParameters.containsKey('lat')) {
          final lat = double.tryParse(uri.queryParameters['lat'] ?? '');
          final lng = double.tryParse(uri.queryParameters['lng'] ?? '');
          if (lat != null && lng != null) {
            initialTarget = LatLng(lat, lng);
            initialSpotName = uri.queryParameters['name'];
          }
        } else if (uri != null && uri.queryParameters.containsKey('data')) {
          final data = uri.queryParameters['data'];
          final parsed = GeoUriParser.parse(data);
          if (parsed != null) {
            initialTarget = LatLng(parsed.latitude, parsed.longitude);
            initialSpotName = parsed.label ?? GeoUriParser.extractLabel(data);
          } else {
            initialSpotName = GeoUriParser.extractLabel(data);
          }
        }
        return MaterialPageRoute<void>(
          builder: (_) => SpotsMapScreen(
            initialMode: SpotsMapMode.addSpot,
            initialTarget: initialTarget,
            initialSpotName: initialSpotName,
          ),
          settings: settings,
        );

      case search:
        return MaterialPageRoute<void>(
          builder: (_) => const SearchSpotsScreen(),
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
