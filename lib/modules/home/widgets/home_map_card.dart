import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../shared/constants/app_assets.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/cubits/spots/spots_state.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/adaptive_navigation.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/pill_button.dart';

/// The interactive Map card shown in the 2-column home grid beside [CarCard].
///
/// Tapping the card opens the full map experience.
class HomeMapCard extends StatelessWidget {
  const HomeMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppDimens.borderRadiusLarge,
        border: Border.all(color: colors.outlineVariant.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: AppDimens.space20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimens.borderRadiusLarge,
        child: InkWell(
          onTap: () {
            Feedback.forTap(context);
            AdaptiveNavigation.openMap(context);
          },
          borderRadius: AppDimens.borderRadiusLarge,
          hoverColor: colors.primary.withAlpha(context.isDarkMode ? 25 : 15),
          highlightColor: colors.primary.withAlpha(
            context.isDarkMode ? 45 : 30,
          ),
          splashColor: colors.primary.withAlpha(context.isDarkMode ? 65 : 45),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.mapButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    _MapArrowAffordance(
                      onPressed: () => AdaptiveNavigation.openMap(context),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.space8),
                const _MapCardVisual(),
                const SizedBox(height: AppDimens.space8),
                Spacer(),
                PillButton(
                  label: l10n.myMap,
                  icon: Icons.explore_rounded,
                  backgroundColor: colors.primary.withAlpha(18),
                  foregroundColor: Colors.blueAccent,
                  style: .tinted,
                  onPressed: () => AdaptiveNavigation.openMap(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapArrowAffordance extends StatelessWidget {
  const _MapArrowAffordance({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Tooltip(
      message: context.l10n.mapButton,
      child: Material(
        color: colors.primary.withAlpha(14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.adaptive.arrow_forward,
              size: AppDimens.iconSmall,
              color: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapCardVisual extends StatelessWidget {
  const _MapCardVisual();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          child: RepaintBoundary(
            child: Lottie.asset(
              AssetProvider.mapLottie,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space6),
        BlocBuilder<SpotsCubit, SpotsState>(
          buildWhen: (prev, curr) => prev.spots.length != curr.spots.length,
          builder: (context, state) {
            final text = state.spots.isNotEmpty
                ? l10n.savedSpotsCount(state.spots.length)
                : l10n.seeAllOnMap;

            return Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ],
    );
  }
}
