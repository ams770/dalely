import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import 'adaptive/adaptive_ui.dart';

/// A primary action button placed in the thumb zone (bottom) with safe-area padding.
/// Adapts across platforms using CupertinoButton on iOS and FilledButton on Android.
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
    final bg = backgroundColor ?? colors.primary;
    final fg = foregroundColor ?? colors.onPrimary;
    final isEnabled = onPressed != null && !isLoading;

    final content = isLoading
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
                    color: fg,
                    size: AppDimens.iconSmall,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: AppDimens.space8),
              ],
              Text(
                label,
                style: context.textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppDimens.space16),
      child: SizedBox(
        width: double.infinity,
        height: AppDimens.primaryButtonHeight,
        child: PlatformInfo.isIOS
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(
                  double.infinity,
                  AppDimens.primaryButtonHeight,
                ),
                color: bg,
                disabledColor: bg.withAlpha(100),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppDimens.radiusLarge),
                ),
                onPressed: isEnabled
                    ? () {
                        HapticFeedback.lightImpact();
                        onPressed!();
                      }
                    : null,
                child: content,
              )
            : FilledButton(
                onPressed: isEnabled ? onPressed : null,
                style: FilledButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppDimens.radiusLarge),
                    ),
                  ),
                ),
                child: content,
              ),
      ),
    );
  }
}

