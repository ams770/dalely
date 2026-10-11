import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

class FeenApp extends StatelessWidget {
  const FeenApp({
    super.key,
    required this.dependencies,
  });

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
      ],
      child: _FeenMaterialApp(
        actionRouter: dependencies.actionRouter,
        notificationService: dependencies.notificationService,
      ),
    );
  }
}

class _FeenMaterialApp extends StatelessWidget {
  const _FeenMaterialApp({
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
            prev.localeCode != curr.localeCode ||
            prev.hasCompletedOnboarding != curr.hasCompletedOnboarding,
        builder: (context, settings) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
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
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (settings.locale != null) {
                return settings.locale;
              }
              if (deviceLocale != null) {
                // 1. Exact match with country code (e.g. ar_EG or ar_SA)
                for (final supported in supportedLocales) {
                  if (supported.languageCode == deviceLocale.languageCode &&
                      supported.countryCode != null &&
                      supported.countryCode == deviceLocale.countryCode) {
                    return supported;
                  }
                }
                // 2. Egyptian match
                if (deviceLocale.countryCode == 'EG') {
                  return const Locale('ar', 'EG');
                }
                // 3. Saudi / Gulf Arabic
                if (deviceLocale.languageCode == 'ar' &&
                    const ['SA', 'AE', 'KW', 'QA', 'BH', 'OM']
                        .contains(deviceLocale.countryCode)) {
                  return const Locale('ar', 'SA');
                }
                // 4. General Arabic fallback
                if (deviceLocale.languageCode == 'ar') {
                  return const Locale('ar', 'EG');
                }
                // 5. English or other language
                for (final supported in supportedLocales) {
                  if (supported.languageCode == deviceLocale.languageCode) {
                    return supported;
                  }
                }
              }
              return const Locale('en');
            },
            initialRoute: settings.hasCompletedOnboarding
                ? AppRouter.home
                : AppRouter.onboarding,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              actionRouter.init(notificationService: notificationService);
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
