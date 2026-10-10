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
          create: (_) => SpotsCubit(
            spotsRepository: dependencies.spotsRepository,
            settingsRepository: dependencies.settingsRepository,
            homeWidgetService: dependencies.homeWidgetService,
          ),
        ),
        BlocProvider<CarProximityCubit>(
          create: (_) => CarProximityCubit(),
        ),
      ],
      child: _FeenMaterialApp(
        homeWidgetService: dependencies.homeWidgetService,
      ),
    );
  }
}

class _FeenMaterialApp extends StatelessWidget {
  _FeenMaterialApp({
    required this.homeWidgetService,
  }) : _actionHandler = WidgetActionHandler(
          navigatorKey: appNavigatorKey,
          homeWidgetService: homeWidgetService,
        );

  final dynamic homeWidgetService;
  final WidgetActionHandler _actionHandler;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.themeMode != curr.themeMode ||
          prev.localeCode != curr.localeCode,
      builder: (context, settings) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Feen',
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
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale.languageCode) {
                  return supported;
                }
              }
            }
            return const Locale('en');
          },
          initialRoute: AppRouter.home,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            _actionHandler.init();
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
