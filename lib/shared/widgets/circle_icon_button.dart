import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// A circular touch button for navigation and secondary screen actions.
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
    final bg = backgroundColor ?? context.colorScheme.surface;
    final fg = foregroundColor ?? context.colorScheme.onSurface;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBorderSide = BorderSide(
      color: context.colorScheme.outline.withAlpha(isDark ? 80 : 120),
      width: 1,
    );

    BorderSide borderSide = defaultBorderSide;
    if (border is Border) {
      final b = border as Border;
      if (b.top.style != BorderStyle.none) {
        borderSide = b.top;
      }
    }

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: bg,
        shape: CircleBorder(side: borderSide),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: fg.withAlpha(35),
          highlightColor: fg.withAlpha(18),
          child: Center(
            child: IconTheme(
              data: IconThemeData(size: iconSize, color: fg),
              child: icon,
            ),
          ),
        ),
      ),
    );

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
