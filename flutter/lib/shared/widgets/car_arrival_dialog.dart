import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_dimens.dart';
import '../utils/adaptive_layout_ext.dart';
import '../utils/context_ext.dart';
import 'adaptive/adaptive_ui.dart';

/// Arrival page/dialog presented when the user is in front of their parked car.
///
/// On phones, presents as a focused full-page flow.
/// On foldable or tablet devices, presents as a modal dialog bounded to the
/// available home/car area rather than taking the entire page over the map.
class CarArrivalDialog extends StatelessWidget {
  const CarArrivalDialog({
    super.key,
    required this.onFoundCar,
    required this.onCantSeeCar,
  });

  final VoidCallback onFoundCar;
  final VoidCallback onCantSeeCar;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    if (context.isWideScreen) {
      final size = MediaQuery.sizeOf(context);
      final isFoldable = context.isFoldableDevice;

      // Compute width of main (home) pane and map pane
      final double mainPaneWidth = isFoldable ? (size.width / 2) : 380.0;
      final double mapPaneWidth = size.width - mainPaneWidth;

      // Dialog is positioned in the map part, leaving the main part open
      final double maxAllowedWidth = isFoldable
          ? (mapPaneWidth - (AppDimens.space16 * 2))
          : 420.0.clamp(280.0, mapPaneWidth - (AppDimens.space16 * 2));
      final double dialogWidth = maxAllowedWidth;

      final double endInset = isFoldable
          ? AppDimens.space16
          : ((mapPaneWidth - dialogWidth) / 2)
              .clamp(AppDimens.space16, mapPaneWidth);

      return Dialog(
        alignment: AlignmentDirectional.centerEnd,
        insetPadding: EdgeInsetsDirectional.only(
          start: AppDimens.space16,
          end: endInset,
          top: AppDimens.space24,
          bottom: AppDimens.space24,
        ).resolve(Directionality.of(context)),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusLarge,
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
            width: 1,
          ),
        ),
        elevation: 6,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: size.height - (AppDimens.space24 * 2),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppDimens.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CarHeroIllustration(),
                const SizedBox(height: AppDimens.space16),
                const _ArrivalTextSection(),
                const SizedBox(height: AppDimens.space20),
                _ActionButtons(
                  onFoundCar: onFoundCar,
                  onCantSeeCar: onCantSeeCar,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog.fullscreen(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space24,
            vertical: AppDimens.space12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const Spacer(),
                  const _CarHeroIllustration(),
                  const SizedBox(height: AppDimens.space24),
                  const _ArrivalTextSection(),
                  const Spacer(),
                  _ActionButtons(
                    onFoundCar: onFoundCar,
                    onCantSeeCar: onCantSeeCar,
                  ),
                  const SizedBox(height: AppDimens.space8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarHeroIllustration extends StatelessWidget {
  const _CarHeroIllustration();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isWide = context.isWideScreen;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 340,
        maxHeight: isWide ? 170 : 220,
      ),
      padding: const EdgeInsetsDirectional.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(15),
        borderRadius: AppDimens.borderRadiusLarge,
        border: Border.all(
          color: colorScheme.primary.withAlpha(45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Image(
          image: AssetProvider.carImage,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class _ArrivalTextSection extends StatelessWidget {
  const _ArrivalTextSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.carArrivalTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
          ),
          child: Text(
            l10n.carArrivalMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onFoundCar, required this.onCantSeeCar});

  final VoidCallback onFoundCar;
  final VoidCallback onCantSeeCar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary Action: "Found my car" (Follows app primary theme color)
        SizedBox(
          width: double.infinity,
          height: AppDimens.primaryButtonHeight,
          child: AdaptiveButton.child(
            onPressed: () {
              Navigator.of(context).pop();
              onFoundCar();
            },
            style: AdaptiveButtonStyle.filled,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded),
                const SizedBox(width: AppDimens.space8),
                Flexible(
                  child: Text(
                    l10n.foundMyCar,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space12),

        // Secondary Action: "Haven't seen the car yet" / "لسه مشوفتش العربيه"
        SizedBox(
          width: double.infinity,
          height: AppDimens.primaryButtonHeight,
          child: AdaptiveButton.child(
            onPressed: () {
              Navigator.of(context).pop();
              onCantSeeCar();
            },
            style: AdaptiveButtonStyle.bordered,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded, color: colorScheme.primary),
                const SizedBox(width: AppDimens.space8),
                Flexible(
                  child: Text(
                    l10n.cantSeeCar,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
