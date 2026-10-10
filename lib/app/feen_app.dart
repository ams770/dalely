import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../shared/cubits/car_proximity/car_proximity_cubit.dart';
import '../shared/cubits/location/location_cubit.dart';
import '../shared/cubits/settings/settings_cubit.dart';
import '../shared/cubits/settings/settings_state.dart';
import '../shared/cubits/spots/spots_cubit.dart';
import '../shared/l10n/generated/app_localizations.dart';
import '../shared/theme/app_theme.dart';
import 'app_router.dart';
import 'bootstrap.dart';
import 'widget_action_handler.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

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
        BlocProvider<SpotsCubit>(
          create: (context) => SpotsCubit(
            spotsRepository: dependencies.spotsRepository,
            settingsRepository: dependencies.settingsRepository,
            homeWidgetService: dependencies.homeWidgetService,
            notificationService: dependencies.notificationService,
            locationCubit: context.read<LocationCubit>(),
          ),
        ),
        BlocProvider<CarProximityCubit>(
          create: (_) => CarProximityCubit(
            notificationService: dependencies.notificationService,
          ),
        ),
      ],
      child: _FeenMaterialApp(
        homeWidgetService: dependencies.homeWidgetService,
        notificationService: dependencies.notificationService,
      ),
    );
  }
}

class _FeenMaterialApp extends StatelessWidget {
  _FeenMaterialApp({
    required this.homeWidgetService,
    required this.notificationService,
  }) : _actionHandler = WidgetActionHandler(
          navigatorKey: appNavigatorKey,
          homeWidgetService: homeWidgetService,
        );

  final dynamic homeWidgetService;
  final dynamic notificationService;
  final WidgetActionHandler _actionHandler;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.themeMode != curr.themeMode ||
          prev.localeCode != curr.localeCode ||
          prev.hasCompletedOnboarding != curr.hasCompletedOnboarding,
      builder: (context, settings) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
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
            _actionHandler.init(notificationService: notificationService);
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
