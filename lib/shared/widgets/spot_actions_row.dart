import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/spot.dart';
import '../services/maps_launcher.dart';
import '../services/share_service.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// The standard 2 actions available for every spot:
/// - "Open in Maps"
/// - "Share"
class SpotActionsRow extends StatelessWidget {
  const SpotActionsRow({
    super.key,
    required this.spot,
    this.onOpenInMaps,
    this.onShare,
    this.showOnMapAction = false,
    this.onShowOnMap,
  });

  final Spot spot;
  final VoidCallback? onOpenInMaps;
  final VoidCallback? onShare;
  final bool showOnMapAction;
  final VoidCallback? onShowOnMap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showOnMapAction && onShowOnMap != null) ...[
          Expanded(
            child: _ActionPillButton(
              icon: Icons.map_outlined,
              label: context.l10n.showOnMap,
              onPressed: onShowOnMap,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
        ],
        Expanded(
          child: _ActionPillButton(
            icon: CupertinoIcons.map,
            label: context.l10n.openInMaps,
            isPrimary: false,
            onPressed:
                onOpenInMaps ??
                () {
                  const MapsLauncher().openDirections(
                    latitude: spot.latitude,
                    longitude: spot.longitude,
                    label: spot.name,
                  );
                },
          ),
        ),
        const SizedBox(width: AppDimens.space8),
        Expanded(
          child: _ActionPillButton(
            icon: Icons.share_outlined,
            label: context.l10n.share,
            onPressed:
                onShare ??
                () {
                  const ShareService().shareSpot(spot, l10n: context.l10n);
                },
          ),
        ),
      ],
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final bg = isPrimary ? colorScheme.primary : context.tokens.pillBackground;
    final fg = isPrimary ? colorScheme.onPrimary : colorScheme.onSurface;

    return Material(
      color: bg,
      borderRadius: AppDimens.borderRadiusMedium,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppDimens.borderRadiusMedium,
        child: Container(
          height: 38,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space8,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppDimens.iconSmall, color: fg),
              const SizedBox(width: AppDimens.space4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
