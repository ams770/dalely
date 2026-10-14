import 'dart:ui' show DisplayFeature, DisplayFeatureType;
import 'package:flutter/material.dart';

import 'adaptive_layout_ext.dart';

final GlobalKey<ScaffoldMessengerState> mainScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

abstract final class AppSnackBar {
  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context, {
    required Widget content,
    Duration duration = defaultDuration,
    SnackBarAction? action,
  }) {
    final messenger =
        mainScaffoldMessengerKey.currentState ??
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final margin = _computeMargin(context);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        action: action,
        margin: margin,
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

    return EdgeInsets.only(
      left: leftMargin.clamp(0.0, screenWidth - 100.0),
      right: rightMargin.clamp(0.0, screenWidth - 100.0),
      bottom: baseBottom,
    );
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
