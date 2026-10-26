import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import 'adaptive/adaptive_ui.dart';

/// A reusable pill-shaped action button with custom colors and optional icon.
/// Uses platform-native styling and haptics (Cupertino on iOS, Material 3 on Android).
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.style,
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
  final AdaptiveButtonStyle? style;
  final EdgeInsetsDirectional padding;

  @override
  Widget build(BuildContext context) {
    final content = Row(
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
    );

    if (PlatformInfo.isIOS) {
      return SizedBox(
        height: height,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size(0, height),
          onPressed: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            padding: padding,
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}

