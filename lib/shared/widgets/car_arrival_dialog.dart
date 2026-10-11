import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// Full-screen arrival page presented when the user is in front of their parked car.
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

    return Dialog.fullscreen(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space24,
            vertical: AppDimens.space12,
          ),
          child: Column(
            children: [
              const _TopBar(),
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
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final theme = context.theme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space12,
            vertical: AppDimens.space6,
          ),
          decoration: BoxDecoration(
            color: tokens.carCardBackground.withAlpha(25),
            borderRadius: AppDimens.borderRadiusFull,
            border: Border.all(
              color: tokens.carCardBackground.withAlpha(60),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.near_me_rounded,
                size: AppDimens.iconSmall,
                color: tokens.carCardBackground,
              ),
              const SizedBox(width: AppDimens.space6),
              Text(
                l10n.carArrivalTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.carCardForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.cancel,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _CarHeroIllustration extends StatelessWidget {
  const _CarHeroIllustration();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 220),
      padding: const EdgeInsetsDirectional.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: tokens.carCardBackground.withAlpha(20),
        borderRadius: AppDimens.borderRadiusLarge,
        border: Border.all(
          color: tokens.carCardBackground.withAlpha(55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.carCardShadow.withAlpha(25),
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
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
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
  const _ActionButtons({
    required this.onFoundCar,
    required this.onCantSeeCar,
  });

  final VoidCallback onFoundCar;
  final VoidCallback onCantSeeCar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final theme = context.theme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary Action: "Found my car"
        SizedBox(
          width: double.infinity,
          height: AppDimens.primaryButtonHeight,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onFoundCar();
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              l10n.foundMyCar,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: tokens.carCardBackground,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppDimens.borderRadiusLarge,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space12),

        // Secondary Action: "Haven't seen the car yet" / "لسه مشوفتش العربيه"
        SizedBox(
          width: double.infinity,
          height: AppDimens.primaryButtonHeight,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onCantSeeCar();
            },
            icon: const Icon(Icons.map_rounded),
            label: Text(
              l10n.cantSeeCar,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(
                color: tokens.carCardBackground.withAlpha(90),
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AppDimens.borderRadiusLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
