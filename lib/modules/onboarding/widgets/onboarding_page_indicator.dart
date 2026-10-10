import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OnboardingCubit, OnboardingState, int>(
      selector: (state) => state.currentPage,
      builder: (context, currentPage) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = index == currentPage;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? context.colorScheme.primary
                    : context.colorScheme.primary.withAlpha(50),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}
