import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../shared/cubits/car_proximity/car_proximity_cubit.dart';
import '../shared/cubits/car_tracking/car_tracking_cubit.dart';
import '../shared/cubits/location/location_cubit.dart';
import '../shared/cubits/settings/settings_cubit.dart';
import '../shared/cubits/settings/settings_state.dart';
import '../shared/cubits/spots/spots_cubit.dart';
import '../shared/cubits/spots/spots_state.dart';
import '../shared/l10n/generated/app_localizations.dart';
import '../shared/services/notification_service.dart';
import '../shared/theme/app_theme.dart';
import '../shared/utils/app_snack_bar.dart';
import 'app_router.dart';
import 'bootstrap.dart';
import 'notification_action_router.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  String? currentRoute;
  Object? currentArguments;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      currentRoute = route.settings.name;
      currentArguments = route.settings.arguments;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      currentRoute = previousRoute.settings.name;
      currentArguments = previousRoute.settings.arguments;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      currentRoute = newRoute.settings.name;
      currentArguments = newRoute.settings.arguments;
    }
  }
}

final AppRouteObserver appRouteObserver = AppRouteObserver();

class DalelyApp extends StatelessWidget {
  const DalelyApp({super.key, required this.dependencies});

  final BootstrapDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(dependencies.settingsRepository),
        ),
        BlocProvider<LocationCubit>(
          create: (_) => LocationCubit(
            locationService: dependencies.locationService,
            headingService: dependencies.headingService,
          ),
        ),
        BlocProvider<CarTrackingCubit>(
          create: (_) => CarTrackingCubit(
            carTrackingService: dependencies.carTrackingService,
          ),
        ),
        BlocProvider<SpotsCubit>(
          create: (context) => SpotsCubit(
            spotsRepository: dependencies.spotsRepository,
            settingsRepository: dependencies.settingsRepository,
            homeWidgetService: dependencies.homeWidgetService,
            notificationService: dependencies.notificationService,
            locationCubit: context.read<LocationCubit>(),
            carTrackingCubit: context.read<CarTrackingCubit>(),
          ),
        ),
        BlocProvider<CarProximityCubit>(
          create: (_) => CarProximityCubit(
            notificationService: dependencies.notificationService,
          ),
        ),
        BlocProvider<AdaptiveNavCubit>(create: (_) => AdaptiveNavCubit()),
      ],
      child: _DalelyMaterialApp(
        actionRouter: dependencies.actionRouter,
        notificationService: dependencies.notificationService,
      ),
    );
  }

  static Locale resolveAppLocale({
    required Locale? userOverride,
    List<Locale>? preferredLocales,
    Locale? deviceLocale,
    required Iterable<Locale> supportedLocales,
  }) {
    // 1. User manual override from settings
    if (userOverride != null) {
      return userOverride;
    }

    // 2. Check preferred locales list from the system
    if (preferredLocales != null && preferredLocales.isNotEmpty) {
      for (final locale in preferredLocales) {
        final match = _matchSupportedLocale(locale, supportedLocales);
        if (match != null) {
          return match;
        }
      }
    }

    // 3. Check single device locale
    if (deviceLocale != null) {
      final match = _matchSupportedLocale(deviceLocale, supportedLocales);
      if (match != null) {
        return match;
      }
    }

    // 4. Default fallback to English
    return const Locale('en');
  }

  static Locale? _matchSupportedLocale(
    Locale locale,
    Iterable<Locale> supportedLocales,
  ) {
    final country = locale.countryCode?.toUpperCase();

    // Arabic handling
    if (locale.languageCode == 'ar') {
      if (country != null) {
        // Exact match with supported locales (e.g. ar_EG or ar_SA)
        for (final supported in supportedLocales) {
          if (supported.languageCode == 'ar' &&
              supported.countryCode?.toUpperCase() == country) {
            return supported;
          }
        }
        // Egyptian dialect match
        if (country == 'EG') {
          return const Locale('ar', 'EG');
        }
        // Saudi / Gulf Arabic dialect match
        if (const ['SA', 'AE', 'KW', 'QA', 'BH', 'OM'].contains(country)) {
          return const Locale('ar', 'SA');
        }
      }
      // General Arabic fallback
      return const Locale('ar', 'EG');
    }

    // English handling
    if (locale.languageCode == 'en') {
      return const Locale('en');
    }

    // Unsupported language
    return null;
  }
}

class _DalelyMaterialApp extends StatelessWidget {
  const _DalelyMaterialApp({
    required this.actionRouter,
    required this.notificationService,
  });

  final NotificationActionRouter actionRouter;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, SettingsState>(
          listenWhen: (prev, curr) =>
              prev.carDistanceNotificationEnabled &&
              !curr.carDistanceNotificationEnabled,
          listener: (context, _) {
            context.read<CarTrackingCubit>().stopCarTracking();
          },
        ),
        BlocListener<SpotsCubit, SpotsState>(
          listenWhen: (prev, curr) => prev.car != curr.car && curr.car == null,
          listener: (context, _) {
            context.read<CarTrackingCubit>().stopCarTracking();
          },
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (prev, curr) =>
            prev.themeMode != curr.themeMode ||
            prev.localeCode != curr.localeCode,
        builder: (context, settings) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            scaffoldMessengerKey: mainScaffoldMessengerKey,
            navigatorObservers: [appRouteObserver],
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeListResolutionCallback: (locales, supportedLocales) {
              return DalelyApp.resolveAppLocale(
                userOverride: settings.locale,
                preferredLocales: locales,
                deviceLocale: locales?.firstOrNull,
                supportedLocales: supportedLocales,
              );
            },
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              return DalelyApp.resolveAppLocale(
                userOverride: settings.locale,
                preferredLocales: null,
                deviceLocale: deviceLocale,
                supportedLocales: supportedLocales,
              );
            },
            initialRoute: settings.hasCompletedOnboarding
                ? AppRouter.home
                : AppRouter.onboarding,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              actionRouter.init(notificationService: notificationService);
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemOverlayStyle(isDark: isDark),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
