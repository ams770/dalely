import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// Vertical action rail for compact dual-screen (iPhone Duo) devices.
/// Sits in the trailing thumb rail directly beneath the hardware status clock.
class DuoActionRail extends StatelessWidget {
  const DuoActionRail({
    super.key,
    required this.onSettings,
    required this.onHistory,
    required this.onMap,
    required this.onAddSpot,
  });

  final VoidCallback onSettings;
  final VoidCallback onHistory;
  final VoidCallback onMap;
  final VoidCallback onAddSpot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: 52.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimens.space12),
          // 1. Settings Action
          _RailIconButton(
            icon: Icons.tune_rounded,
            tooltip: l10n.settingsTooltip,
            onPressed: onSettings,
          ),
        
          const SizedBox(height: AppDimens.space16),
          _PrimaryAddRailButton(tooltip: l10n.addSpot, onPressed: onAddSpot),
        ],
      ),
    );
  }
}

class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final iconColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 44.0,
        height: 44.0,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: AppDimens.borderRadiusSmall,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 60 : 20),
              blurRadius: 6.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppDimens.borderRadiusSmall,
          child: InkWell(
            onTap: () {
              Feedback.forTap(context);
              onPressed();
            },
            borderRadius: AppDimens.borderRadiusSmall,
            hoverColor: iconColor.withAlpha(isDark ? 35 : 20),
            highlightColor: iconColor.withAlpha(isDark ? 65 : 40),
            splashColor: iconColor.withAlpha(isDark ? 85 : 60),
            child: Center(child: Icon(icon, size: 20.0, color: iconColor)),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAddRailButton extends StatelessWidget {
  const _PrimaryAddRailButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 46.0,
        height: 46.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lightPrimary,
          boxShadow: [
            BoxShadow(
              color: AppColors.lightPrimary.withAlpha(isDark ? 110 : 90),
              blurRadius: 8.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Feedback.forTap(context);
              onPressed();
            },
            hoverColor: Colors.white.withAlpha(40),
            highlightColor: Colors.white.withAlpha(70),
            splashColor: Colors.white.withAlpha(90),
            child: const Center(
              child: Icon(Icons.add_rounded, size: 24.0, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
