import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';

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

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Row(
        children: [
          Expanded(
            child: _ThemeCard(
              title: l10n.themeSystem,
              icon: Icons.brightness_auto_rounded,
              accentColor: primary,
              isSelected: currentMode == ThemeMode.system,
              onTap: () => _select(context, ThemeMode.system),
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: _ThemeCard(
              title: l10n.themeLight,
              icon: Icons.light_mode_rounded,
              accentColor: const Color(0xFFF59E0B),
              isSelected: currentMode == ThemeMode.light,
              onTap: () => _select(context, ThemeMode.light),
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: _ThemeCard(
              title: l10n.themeDark,
              icon: Icons.dark_mode_rounded,
              accentColor: const Color(0xFF818CF8),
              isSelected: currentMode == ThemeMode.dark,
              onTap: () => _select(context, ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  }

  void _select(BuildContext context, ThemeMode mode) {
    if (mode == currentMode) return;

    HapticFeedback.selectionClick();
    onModeChanged(mode);
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 250);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.isDarkMode;

    final backgroundColor = isSelected
        ? (isDark
              ? scheme.primaryContainer.withAlpha(75)
              : AppColors.lightPrimaryContainer)
        : (isDark ? scheme.surfaceContainerLow : scheme.surface);

    final borderColor = isSelected
        ? scheme.primary
        : scheme.outlineVariant.withAlpha(isDark ? 110 : 150);

    final foregroundColor = isSelected
        ? (isDark ? Colors.white : AppColors.lightTextPrimary)
        : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimens.borderRadiusLarge,
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space8,
              vertical: AppDimens.space12,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppDimens.borderRadiusLarge,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withAlpha(isDark ? 35 : 20),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection indicator
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: AnimatedScale(
                    duration: _duration,
                    curve: _curve,
                    scale: isSelected ? 1 : 0.5,
                    child: AnimatedOpacity(
                      duration: _duration,
                      opacity: isSelected ? 1 : 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: _duration,
                      curve: _curve,
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(
                          isSelected ? 35 : (isDark ? 20 : 14),
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AnimatedScale(
                          duration: _duration,
                          curve: _curve,
                          scale: isSelected ? 1.08 : 1,
                          child: Icon(
                            icon,
                            size: 21,
                            color: isSelected
                                ? accentColor
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimens.space8),

                    AnimatedDefaultTextStyle(
                      duration: _duration,
                      curve: _curve,
                      style: (context.textTheme.bodyMedium ?? const TextStyle())
                          .copyWith(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: foregroundColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: Text(title, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
