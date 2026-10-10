import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// Full-screen arrival dialog presented when the user returns near their parked car.
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
    final l10n = context.l10n;
    final tokens = context.tokens;
    final theme = context.theme;

    return Dialog.fullscreen(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppDimens.space24),
          child: Column(
            children: [
              // Top dismiss button
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: l10n.cancel,
                ),
              ),
              const Spacer(),

              // Animated/Prominent Car Icon Badge
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.carCardBackground.withAlpha(30),
                  border: Border.all(
                    color: tokens.carCardBackground.withAlpha(80),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.carCardBackground,
                      boxShadow: [
                        BoxShadow(
                          color: tokens.carCardShadow,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space32),

              // Title
              Text(
                l10n.carArrivalTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              // Subtitle
              Text(
                l10n.carArrivalMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const Spacer(),

              // Primary Action: "I found my car"
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
                    l10n.iFoundMyCar,
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

              // Secondary Action: "I can't see the car"
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
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppDimens.borderRadiusLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space8),
            ],
          ),
        ),
      ),
    );
  }
}
