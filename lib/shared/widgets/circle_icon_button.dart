import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import 'adaptive/adaptive_ui.dart';

/// A circular touch button for navigation and secondary screen actions.
/// Uses native Liquid Glass on iOS (iOS 26+ / Cupertino) and Adaptive MD3 on Android.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = AppDimens.iconButtonSize,
    this.iconSize = AppDimens.iconLarge,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? context.colorScheme.onSurface;
    final isDark = context.isDarkMode;

    Widget button;

    if (PlatformInfo.isIOS) {
      final defaultBg = isDark
          ? context.colorScheme.surfaceContainerHigh
          : context.colorScheme.surfaceContainerLow;

      // iOS: Authentic Liquid Glass with backdrop blur, highlight border and haptics
      button = ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? defaultBg,
              border:
                  border ??
                  Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(35)
                        : Colors.white.withAlpha(180),
                    width: 0.5,
                  ),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size(size, size),
              onPressed: onPressed == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onPressed!();
                    },
              child: Center(
                child: IconTheme(
                  data: IconThemeData(size: iconSize, color: fg),
                  child: icon,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Android / Other: Adaptive Material 3 tonal elevation with ink ripple
      final defaultBg = isDark
          ? context.colorScheme.surfaceContainerHigh
          : context.colorScheme.surfaceContainerLow;

      button = Material(
        color: backgroundColor ?? defaultBg,
        shape: border is Border
            ? CircleBorder(
                side: BorderSide(
                  color: (border! as Border).top.color,
                  width: (border! as Border).top.width,
                ),
              )
            : const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: IconTheme(
                data: IconThemeData(size: iconSize, color: fg),
                child: icon,
              ),
            ),
          ),
        ),
      );
    }

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimens.minTouchTarget,
        minHeight: AppDimens.minTouchTarget,
      ),
      child: Center(child: button),
    );
  }
}
