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
    final bg = backgroundColor ?? context.colorScheme.primary;
    final fg = foregroundColor ?? context.colorScheme.onPrimary;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDimens.space16),
        child: SizedBox(
          width: double.infinity,
          height: AppDimens.primaryButtonHeight,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              shape: const RoundedRectangleBorder(
                borderRadius: AppDimens.borderRadiusLarge,
              ),
              elevation: 4,
              shadowColor: bg.withAlpha(90),
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
                        icon!,
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
                  ),
          ),
        ),
      ),
    );
  }
}
