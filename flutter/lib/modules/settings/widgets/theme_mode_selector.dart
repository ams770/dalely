import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';

/// A modern, visual, and smooth theme mode selector.
///
/// Presents interactive cards for System, Light, and Dark modes
/// with vibrant icons, tactile haptic feedback, and smooth animated transitions.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = context.colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: _ThemeCard(
            mode: ThemeMode.system,
            title: l10n.themeSystem,
            icon: Icons.brightness_auto_rounded,
            accentColor: primary,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => onModeChanged(ThemeMode.system),
          ),
        ),
        const SizedBox(width: AppDimens.space8),
        Expanded(
          child: _ThemeCard(
            mode: ThemeMode.light,
            title: l10n.themeLight,
            icon: Icons.light_mode_rounded,
            accentColor: const Color(0xFFF59E0B),
            isSelected: currentMode == ThemeMode.light,
            onTap: () => onModeChanged(ThemeMode.light),
          ),
        ),
        const SizedBox(width: AppDimens.space8),
        Expanded(
          child: _ThemeCard(
            mode: ThemeMode.dark,
            title: l10n.themeDark,
            icon: Icons.dark_mode_rounded,
            accentColor: const Color(0xFF818CF8),
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => onModeChanged(ThemeMode.dark),
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.mode,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String title;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const Curve _animationCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDarkMode;

    final backgroundColor = isSelected
        ? (isDark
            ? colorScheme.primaryContainer.withAlpha(70)
            : AppColors.lightPrimaryContainer)
        : (isDark
            ? colorScheme.surface.withAlpha(80)
            : Colors.black.withAlpha(6));

    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outline.withAlpha(isDark ? 50 : 80);

    final iconBadgeColor = isSelected
        ? accentColor.withAlpha(isDark ? 50 : 30)
        : (isDark ? Colors.white.withAlpha(14) : Colors.black.withAlpha(8));

    final iconColor = isSelected ? accentColor : colorScheme.onSurfaceVariant;

    final textColor = isSelected
        ? (isDark ? Colors.white : AppColors.lightTextPrimary)
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, ${isSelected ? "selected" : ""}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: AppDimens.borderRadiusLarge,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: _animationCurve,
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppDimens.space12,
              horizontal: AppDimens.space8,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppDimens.borderRadiusLarge,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(isDark ? 45 : 25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge
                AnimatedContainer(
                  duration: _animationDuration,
                  curve: _animationCurve,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBadgeColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),

                // Title
                AnimatedDefaultTextStyle(
                  duration: _animationDuration,
                  curve: _animationCurve,
                  style: (context.textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Text(title, textAlign: TextAlign.center),
                ),
                const SizedBox(height: AppDimens.space8),

                // Selection Radio / Check Indicator
                _SelectionIndicator(
                  isSelected: isSelected,
                  primaryColor: colorScheme.primary,
                  onPrimaryColor: colorScheme.onPrimary,
                  outlineColor: colorScheme.outline.withAlpha(isDark ? 80 : 120),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.isSelected,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.outlineColor,
  });

  final bool isSelected;
  final Color primaryColor;
  final Color onPrimaryColor;
  final Color outlineColor;

  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const Curve _animationCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _animationDuration,
      curve: _animationCurve,
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? primaryColor : outlineColor,
          width: isSelected ? 2.0 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedOpacity(
        duration: _animationDuration,
        curve: _animationCurve,
        opacity: isSelected ? 1.0 : 0.0,
        child: Icon(
          Icons.check_rounded,
          size: 11,
          color: onPrimaryColor,
        ),
      ),
    );
  }
}
