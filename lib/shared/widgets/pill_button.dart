import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// A reusable pill-shaped action button with custom colors and optional icon.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.height = AppDimens.minTouchTarget,
    this.padding = const EdgeInsetsDirectional.symmetric(
      horizontal: AppDimens.space12,
    ),
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final double height;
  final EdgeInsetsDirectional padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppDimens.borderRadiusFull,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppDimens.borderRadiusFull,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppDimens.borderRadiusFull,
            splashColor: foregroundColor.withAlpha(25),
            highlightColor: foregroundColor.withAlpha(15),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: AppDimens.iconSmall,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: AppDimens.space6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
