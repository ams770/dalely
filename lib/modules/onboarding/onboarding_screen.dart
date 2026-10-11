import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_router.dart';
import '../../shared/constants/app_assets.dart';
import '../../shared/cubits/location/location_cubit.dart';
import '../../shared/cubits/settings/settings_cubit.dart';
import '../../shared/cubits/settings/settings_state.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/context_ext.dart';
import 'cubit/onboarding_cubit.dart';
import 'widgets/onboarding_bottom_bar.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/onboarding_top_bar.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    final locationCubit = context.read<LocationCubit>();

    return BlocProvider<OnboardingCubit>(
      create: (_) => OnboardingCubit(
        settingsCubit: settingsCubit,
        locationCubit: locationCubit,
      ),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final l10n = context.l10n;

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (prev, curr) =>
          prev.hasCompletedOnboarding != curr.hasCompletedOnboarding &&
          curr.hasCompletedOnboarding,
      listener: (context, state) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      },
      child: Scaffold(
        backgroundColor: context.isDarkMode ? null : Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Top Bar with Skip Action
                const OnboardingTopBar(),

                // Page View with Onboarding Steps
                Expanded(
                  child: PageView(
                    controller: cubit.pageController,
                    onPageChanged: cubit.onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      OnboardingPage(
                        imageAsset: AssetProvider.onboarding1,
                        title: l10n.onboarding1Title,
                        body: l10n.onboarding1Body,
                      ),
                      OnboardingPage(
                        imageAsset: AssetProvider.onboarding2,
                        title: l10n.onboarding2Title,
                        body: l10n.onboarding2Body,
                      ),
                      OnboardingPage(
                        imageAsset: AssetProvider.onboarding3,
                        title: l10n.onboarding3Title,
                        body: l10n.onboarding3Body,
                      ),
                    ],
                  ),
                ),

                // Bottom Bar with Indicator and Action Buttons
                const OnboardingBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
