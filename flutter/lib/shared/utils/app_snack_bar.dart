import 'dart:ui' show DisplayFeature, DisplayFeatureType;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../theme/app_colors.dart';
import 'adaptive_layout_ext.dart';

final GlobalKey<ScaffoldMessengerState> mainScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

abstract final class AppSnackBar {
  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context, {
    Widget? content,
    String? message,
    Duration duration = defaultDuration,
    SnackBarAction? action,
    String? actionLabel,
    VoidCallback? onAction,
    Widget? icon,
    IconData? iconData,
    Color? iconColor,
    Color? iconBgColor,
    bool showIcon = true,
  }) {
    assert(
      content != null || message != null,
      'Either content or message must be provided to AppSnackBar.show',
    );
    final messenger =
        ScaffoldMessenger.maybeOf(context) ??
        mainScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final margin = _computeMargin(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: margin,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: FriendlyAlert(
          content: content,
          message: message,
          action: action,
          actionLabel: actionLabel,
          onAction: onAction,
          icon: icon,
          iconData: iconData,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          showIcon: showIcon,
        ),
      ),
    );
  }

  @visibleForTesting
  static EdgeInsets computeMargin(BuildContext context) =>
      _computeMargin(context);

  static EdgeInsets _computeMargin(BuildContext context) {
    const double baseHorizontal = 20.0;
    const double baseBottom = 100.0;

    if (!context.isWideScreen) {
      return const EdgeInsets.symmetric(
        horizontal: baseHorizontal,
        vertical: baseBottom,
      );
    }

    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // If the enclosing Scaffold is already sized to an adaptive sub-pane
    // (e.g. tablet two-pane layout where _HomePane or detail pane has its own Scaffold),
    // that sub-pane Scaffold already restricts the layout horizontally.
    final scaffoldBox = _findScaffoldRenderBox(context);
    if (scaffoldBox != null && scaffoldBox.size.width < screenWidth - 50.0) {
      return const EdgeInsets.symmetric(
        horizontal: baseHorizontal,
        vertical: baseBottom,
      );
    }

    // Determine the physical horizontal center of the initiating widget.
    double? widgetCenterX;
    final box = _findAttachedRenderBox(context);
    if (box != null) {
      final globalPos = box.localToGlobal(Offset.zero);
      widgetCenterX = globalPos.dx + box.size.width / 2;
    }

    // Default to the home / start side if unknown.
    final bool isLeftPart = widgetCenterX != null
        ? widgetCenterX < screenWidth / 2
        : !isRtl;

    // Check for physical vertical hinge on dual-screen foldables.
    DisplayFeature? verticalHinge;
    final features = MediaQuery.displayFeaturesOf(context);
    for (final f in features) {
      if ((f.type == DisplayFeatureType.hinge ||
              f.type == DisplayFeatureType.fold) &&
          f.bounds.top <= 0 &&
          f.bounds.bottom >= size.height &&
          f.bounds.width > 1) {
        verticalHinge = f;
        break;
      }
    }

    final isFoldable = context.isFoldableDevice;

    double leftMargin;
    double rightMargin;

    if (verticalHinge != null) {
      if (isLeftPart) {
        leftMargin = baseHorizontal;
        rightMargin = screenWidth - verticalHinge.bounds.left + baseHorizontal;
      } else {
        leftMargin = verticalHinge.bounds.right + baseHorizontal;
        rightMargin = baseHorizontal;
      }
    } else if (isFoldable) {
      // Foldable screen split into 2 equal parts with 12dp separator
      const double separatorWidth = 12.0;
      final double halfWithGap = (screenWidth + separatorWidth) / 2;
      if (isLeftPart) {
        leftMargin = baseHorizontal;
        rightMargin = halfWithGap + baseHorizontal;
      } else {
        leftMargin = halfWithGap + baseHorizontal;
        rightMargin = baseHorizontal;
      }
    } else {
      // Tablet layout: fixed 380 sidebar and remaining detail pane
      const double sidebarWidth = 380.0;
      const double separatorWidth = 12.0;
      final double detailStart = sidebarWidth + separatorWidth;

      if (!isRtl) {
        if (isLeftPart) {
          leftMargin = baseHorizontal;
          rightMargin = screenWidth - sidebarWidth + baseHorizontal;
        } else {
          leftMargin = detailStart + baseHorizontal;
          rightMargin = baseHorizontal;
        }
      } else {
        // In RTL, the 380 sidebar is on the right
        final double sidebarStart = screenWidth - sidebarWidth;
        if (isLeftPart) {
          leftMargin = baseHorizontal;
          rightMargin =
              screenWidth - sidebarStart + separatorWidth + baseHorizontal;
        } else {
          leftMargin = sidebarStart + baseHorizontal;
          rightMargin = baseHorizontal;
        }
      }
    }

    // Safety guard: Ensure margins never exceed available width
    final double containerWidth = scaffoldBox?.size.width ?? screenWidth;
    if (leftMargin + rightMargin > containerWidth - 200.0) {
      return const EdgeInsets.symmetric(
        horizontal: baseHorizontal,
        vertical: baseBottom,
      );
    }

    return EdgeInsets.only(
      left: leftMargin.clamp(0.0, screenWidth - 100.0),
      right: rightMargin.clamp(0.0, screenWidth - 100.0),
      bottom: baseBottom,
    );
  }

  static RenderBox? _findScaffoldRenderBox(BuildContext context) {
    if (!context.mounted) return null;
    RenderBox? scaffoldBox;
    context.visitAncestorElements((element) {
      if (element.widget is Scaffold) {
        final ro = element.renderObject;
        if (ro is RenderBox && ro.hasSize && ro.attached) {
          scaffoldBox = ro;
          return false;
        }
      }
      return true;
    });
    return scaffoldBox;
  }

  static RenderBox? _findAttachedRenderBox(BuildContext context) {
    if (!context.mounted) return null;
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize && ro.attached) {
      return ro;
    }

    RenderBox? ancestorBox;
    context.visitAncestorElements((element) {
      final ancestorRo = element.renderObject;
      if (ancestorRo is RenderBox && ancestorRo.hasSize && ancestorRo.attached) {
        ancestorBox = ancestorRo;
        return false;
      }
      return true;
    });
    return ancestorBox;
  }
}

/// Friendly alert pill styled like modern compact toasts.
///
/// Features a capsule / stadium shape with:
/// - In dark mode: dark charcoal pill (`AppColors.alertDark`), white text, and light blue action.
/// - In light mode: clean white pill (`AppColors.alertLight`), deep navy text, and primary blue action.
/// - An emerald circular badge with dark checkmark icon.
/// - Fluid intrinsic width with overflow protection.
class FriendlyAlert extends StatelessWidget {
  const FriendlyAlert({
    super.key,
    this.content,
    this.message,
    this.action,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.iconData,
    this.iconColor,
    this.iconBgColor,
    this.showIcon = true,
  }) : assert(
          content != null || message != null,
          'Either content or message must be provided',
        );

  final Widget? content;
  final String? message;
  final SnackBarAction? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? icon;
  final IconData? iconData;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pillBg = isDark ? AppColors.alertDark : AppColors.alertLight;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final actionColor =
        isDark ? AppColors.alertActionDark : AppColors.lightPrimary;
    final borderColor = isDark
        ? const Color(0x22FFFFFF)
        : const Color(0x18000000);

    final String? effectiveActionLabel = action?.label ?? actionLabel;
    final VoidCallback? effectiveOnAction = action?.onPressed ?? onAction;
    final bool hasAction =
        effectiveActionLabel != null && effectiveOnAction != null;

    final Widget contentWidget = content ?? Text(message!);

    final Widget? badgeWidget = icon ??
        (showIcon
            ? FriendlyAlertBadge(
                icon: iconData,
                iconColor: iconColor,
                backgroundColor: iconBgColor,
              )
            : null);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 48.0,
          ),
          decoration: ShapeDecoration(
            color: pillBg,
            shape: StadiumBorder(
              side: BorderSide(color: borderColor, width: 0.5),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 90 : 25),
                blurRadius: 18.0,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsetsDirectional.only(
            start: badgeWidget != null ? 14.0 : 20.0,
            end: hasAction ? 14.0 : 20.0,
            top: 10.0,
            bottom: 10.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (badgeWidget != null) ...[
                badgeWidget,
                const SizedBox(width: 12.0),
              ],
              Flexible(
                fit: FlexFit.loose,
                child: DefaultTextStyle.merge(
                  style: (theme.textTheme.bodyMedium ?? const TextStyle())
                      .copyWith(
                    color: textColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  child: contentWidget,
                ),
              ),
              if (hasAction) ...[
                const SizedBox(width: 14.0),
                FriendlyAlertAction(
                  label: effectiveActionLabel,
                  textColor: actionColor,
                  onPressed: effectiveOnAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular badge (emerald circle with dark checkmark).
class FriendlyAlertBadge extends StatelessWidget {
  const FriendlyAlertBadge({
    super.key,
    this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    const double size = 24.0;
    final bg = backgroundColor ?? AppColors.alertSuccessBadge;
    final fg = iconColor ?? AppColors.alertSuccessIcon;
    final iconData = icon ?? Icons.check_rounded;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        iconData,
        size: 15.0,
        color: fg,
      ),
    );
  }
}

/// Friendly alert action button ("Undo", etc.).
class FriendlyAlertAction extends StatelessWidget {
  const FriendlyAlertAction({
    super.key,
    required this.label,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100.0),
          onTap: () {
            HapticFeedback.lightImpact();
            (ScaffoldMessenger.maybeOf(context) ??
                    mainScaffoldMessengerKey.currentState)
                ?.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
