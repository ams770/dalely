import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import 'onboarding_page_indicator.dart';

class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final l10n = context.l10n;
    final theme = context.theme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDimens.space24,
          AppDimens.space8,
          AppDimens.space24,
          AppDimens.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Indicator Dots
            const OnboardingPageIndicator(),
            const SizedBox(height: AppDimens.space24),

            // Action Button(s)
            BlocBuilder<OnboardingCubit, OnboardingState>(
              buildWhen: (prev, curr) =>
                  prev.currentPage != curr.currentPage ||
                  prev.isCompleting != curr.isCompleting,
              builder: (context, state) {
                if (state.isLastPage) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Allow Location Access Primary Button
                      FilledButton(
                        onPressed: state.isCompleting
                            ? null
                            : cubit.allowLocationAndComplete,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(
                            double.infinity,
                            AppDimens.primaryButtonHeight,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppDimens.borderRadiusLarge,
                          ),
                        ),
                        child: state.isCompleting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.near_me_outlined,
                                    size: AppDimens.iconMedium,
                                  ),
                                  const SizedBox(width: AppDimens.space8),
                                  Text(
                                    l10n.onboardingAllowLocation,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: AppDimens.space8),

                      // Not Now Secondary Button
                      TextButton(
                        onPressed: state.isCompleting
                            ? null
                            : cubit.completeWithoutLocation,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        child: Text(l10n.onboardingNotNow),
                      ),
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Next Button
                    FilledButton(
                      onPressed: cubit.nextPage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          AppDimens.primaryButtonHeight,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppDimens.borderRadiusLarge,
                        ),
                      ),
                      child: Text(
                        l10n.onboardingNext,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space8),

                    // Spacer placeholder to match page 3 height
                    const SizedBox(height: 44),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
