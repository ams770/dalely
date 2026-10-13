import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/adaptive_navigation.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/pill_button.dart';

/// Top header for the Home screen: Settings button and contextual "Add Spot" action.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final hasSpots = context.select<SpotsCubit, bool>(
      (cubit) => cubit.state.totalSavedCount > 0,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleIconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: context.l10n.settingsTooltip,
            onPressed: () {
              AdaptiveNavigation.openSettings(context);
            },
          ),
          const Spacer(),
          if (hasSpots)
            _AddSpotHeaderButton(
              onPressed: () {
                AdaptiveNavigation.openSaveSpot(context);
              },
            ),
        ],
      ),
    );
  }
}

class _AddSpotHeaderButton extends StatelessWidget {
  const _AddSpotHeaderButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return PillButton(
      label: context.l10n.addSpot,
      icon: Icons.add_rounded,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space16,
      ),
      onPressed: onPressed,
    );
  }
}
