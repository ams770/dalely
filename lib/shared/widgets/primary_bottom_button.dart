import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// A primary action button placed in the thumb zone (bottom) with safe-area padding.
class PrimaryBottomButton extends StatelessWidget {
  const PrimaryBottomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDarkMode;
    final bg = backgroundColor ?? colors.primary;
    final fg = foregroundColor ?? colors.onPrimary;
    final isEnabled = onPressed != null && !isLoading;

    // Friendly soft tinted disabled colors matching brand identity
    final disabledBg = isDark ? bg.withAlpha(45) : bg.withAlpha(35);
    final disabledFg = isDark ? Colors.white.withAlpha(90) : bg.withAlpha(120);
    final currentFg = isEnabled ? fg : disabledFg;

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppDimens.space16),
      child: SizedBox(
        width: double.infinity,
        height: AppDimens.primaryButtonHeight,
        child: FilledButton(
          onPressed: isLoading || onPressed == null
              ? null
              : () {
                  Feedback.forTap(context);
                  onPressed!();
                },
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: disabledBg,
            disabledForegroundColor: disabledFg,
            shape: const RoundedRectangleBorder(
              borderRadius: AppDimens.borderRadiusLarge,
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return fg.withAlpha(isDark ? 55 : 40);
              }
              if (states.contains(WidgetState.hovered)) {
                return fg.withAlpha(isDark ? 30 : 20);
              }
              return null;
            }),
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      IconTheme(
                        data: IconThemeData(
                          color: currentFg,
                          size: AppDimens.iconSmall,
                        ),
                        child: icon!,
                      ),
                      const SizedBox(width: AppDimens.space8),
                    ],
                    Text(
                      label,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: currentFg,
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
