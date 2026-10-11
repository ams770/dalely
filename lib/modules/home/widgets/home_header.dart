import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_router.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/cubits/spots/spots_state.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';

/// Top header for the Home screen: "Where to?", saved count, Map shortcut, and Settings button.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

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
          Expanded(
            child: Text(
              context.l10n.homeGreeting,
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _MapHeaderButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.spotsMap);
            },
          ),
          const SizedBox(width: AppDimens.space8),
          CircleIconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: context.l10n.settingsTooltip,
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.settings);
            },
          ),
        ],
      ),
    );
  }
}

class _MapHeaderButton extends StatelessWidget {
  const _MapHeaderButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: AppDimens.borderRadiusFull,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppDimens.borderRadiusFull,
        child: Container(
          height: AppDimens.iconButtonSize,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
          ),
          decoration: BoxDecoration(
            borderRadius: AppDimens.borderRadiusFull,
            border: Border.all(
              color: colorScheme.outline.withAlpha(120),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: AppDimens.iconSmall,
                color: colorScheme.primary,
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                context.l10n.mapButton,
                style: context.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
