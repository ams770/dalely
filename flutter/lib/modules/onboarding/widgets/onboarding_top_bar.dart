import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/adaptive/adaptive_ui.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final l10n = context.l10n;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          top: AppDimens.space8,
          end: AppDimens.space16,
          start: AppDimens.space16,
        ),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BlocSelector<OnboardingCubit, OnboardingState, bool>(
                selector: (state) => state.isLastPage,
                builder: (context, isLastPage) {
                  if (isLastPage) {
                    return const SizedBox.shrink();
                  }

                  return AdaptiveButton(
                    onPressed: cubit.completeWithoutLocation,
                    style: AdaptiveButtonStyle.plain,
                    textColor: context.colorScheme.primary,
                    label: l10n.onboardingSkip,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
