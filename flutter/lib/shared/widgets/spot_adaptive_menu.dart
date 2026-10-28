import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/spot.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import 'circle_icon_button.dart';

/// Actions available for a spot in the adaptive popup menu.
enum SpotCardAction {
  share,
  edit,
  openInMaps,
  delete,
}

/// Displays a high-performance, 100% pure Flutter popup menu matching the native
/// liquid glass aesthetic with 4 actions:
/// 1. Share
/// 2. Edit
/// 3. Open in Map
/// 4. Delete
abstract final class SpotAdaptiveMenu {
  static void handleActionSelected({
    required SpotCardAction action,
    required VoidCallback onShare,
    VoidCallback? onEdit,
    required VoidCallback onOpenInMaps,
    required VoidCallback onDelete,
  }) {
    switch (action) {
      case SpotCardAction.share:
        onShare();
      case SpotCardAction.edit:
        onEdit?.call();
      case SpotCardAction.openInMaps:
        onOpenInMaps();
      case SpotCardAction.delete:
        onDelete();
    }
  }

  static Future<void> show({
    required BuildContext context,
    required Spot spot,
    required VoidCallback onShare,
    VoidCallback? onEdit,
    required VoidCallback onOpenInMaps,
    required VoidCallback onDelete,
    Offset? globalPosition,
  }) async {
    HapticFeedback.mediumImpact();
    final theme = context.theme;
    final l10n = context.l10n;
    final isDark = context.isDarkMode;

    final RenderBox? overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    RelativeRect position;
    if (globalPosition != null) {
      position = RelativeRect.fromRect(
        Rect.fromCenter(center: globalPosition, width: 0, height: 0),
        Offset.zero & overlay.size,
      );
    } else {
      final RenderBox? button = context.findRenderObject() as RenderBox?;
      if (button != null && button.hasSize) {
        final topLeft =
            overlay.globalToLocal(button.localToGlobal(Offset.zero));
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        // Anchor at the end of the row (right edge in LTR, left edge in RTL)
        final endX = isRtl ? topLeft.dx : (topLeft.dx + button.size.width);
        final targetY = globalPosition?.dy ?? (topLeft.dy + button.size.height * 0.1);
        final anchorRect = Rect.fromLTWH(
          endX,
          targetY,
          0,
          button.size.height * 0.8,
        );
        position = RelativeRect.fromRect(
          anchorRect,
          Offset.zero & overlay.size,
        );
      } else {
        position = RelativeRect.fromRect(
          Rect.fromCenter(
            center: overlay.size.center(Offset.zero),
            width: 0,
            height: 0,
          ),
          Offset.zero & overlay.size,
        );
      }
    }

    final surfaceColor = isDark
        ? const Color(0xF21E293B)
        : const Color(0xF8FFFFFF);
    final borderColor = isDark
        ? Colors.white.withAlpha(25)
        : Colors.black.withAlpha(15);
    final iconColor = context.colorScheme.onSurface;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    );

    final selected = await showMenu<SpotCardAction>(
      context: context,
      position: position,
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: Colors.black.withAlpha(isDark ? 80 : 35),
      surfaceTintColor: Colors.transparent,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimens.borderRadiusMedium,
        side: BorderSide(color: borderColor, width: 0.5),
      ),
      items: [
        PopupMenuItem<SpotCardAction>(
          value: SpotCardAction.share,
          height: 44,
          child: Row(
            children: [
              Icon(Icons.share_rounded, size: 20, color: iconColor),
              const SizedBox(width: AppDimens.space12),
              Text(l10n.share, style: textStyle),
            ],
          ),
        ),
        if (onEdit != null)
          PopupMenuItem<SpotCardAction>(
            value: SpotCardAction.edit,
            height: 44,
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 20, color: iconColor),
                const SizedBox(width: AppDimens.space12),
                Text(l10n.editSpot, style: textStyle),
              ],
            ),
          ),
        PopupMenuItem<SpotCardAction>(
          value: SpotCardAction.openInMaps,
          height: 44,
          child: Row(
            children: [
              Icon(Icons.directions_rounded, size: 20, color: iconColor),
              const SizedBox(width: AppDimens.space12),
              Text(l10n.openInMaps, style: textStyle),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<SpotCardAction>(
          value: SpotCardAction.delete,
          height: 44,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppDimens.space12),
              Text(
                l10n.delete,
                style: textStyle?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );

    if (selected != null) {
      handleActionSelected(
        action: selected,
        onShare: onShare,
        onEdit: onEdit,
        onOpenInMaps: onOpenInMaps,
        onDelete: onDelete,
      );
    }
  }
}

/// A trailing button that opens the popup menu for a spot on tap.
class SpotAdaptiveMenuButton extends StatelessWidget {
  const SpotAdaptiveMenuButton({
    super.key,
    required this.spot,
    required this.onShare,
    this.onEdit,
    required this.onOpenInMaps,
    required this.onDelete,
    this.size = 32,
    this.iconSize = 18,
  });

  final Spot spot;
  final VoidCallback onShare;
  final VoidCallback? onEdit;
  final VoidCallback onOpenInMaps;
  final VoidCallback onDelete;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (btnContext) => CircleIconButton(
        icon: const Icon(Icons.more_vert_rounded),
        tooltip: context.l10n.settingsTooltip,
        size: size,
        iconSize: iconSize,
        backgroundColor: Colors.transparent,
        foregroundColor:
            context.colorScheme.onSurfaceVariant.withAlpha(180),
        onPressed: () {
          SpotAdaptiveMenu.show(
            context: btnContext,
            spot: spot,
            onShare: onShare,
            onEdit: onEdit,
            onOpenInMaps: onOpenInMaps,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}
