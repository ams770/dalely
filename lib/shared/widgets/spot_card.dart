import 'package:flutter/material.dart';

import '../models/spot.dart';
import '../services/maps_launcher.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import '../utils/time_ago_formatter.dart';
import 'category_badge.dart';
import 'info_pill.dart';
import 'spot_actions_row.dart';

/// A card representing a saved spot in lists or bottom sheets.
class SpotCard extends StatelessWidget {
  const SpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.onLongPress,
    this.onShowOnMap,
    this.onOpenInMaps,
    this.onShare,
    this.isFavorite = false,
  });

  final Spot spot;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowOnMap;
  final VoidCallback? onOpenInMaps;
  final VoidCallback? onShare;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onShowOnMap ?? onTap,
        onLongPress: onLongPress,
        borderRadius: AppDimens.borderRadiusLarge,
        splashColor: theme.colorScheme.primary.withAlpha(20),
        highlightColor: theme.colorScheme.primary.withAlpha(10),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppDimens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CategoryBadge(category: spot.category),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                spot.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isFavorite) ...[
                              const SizedBox(width: AppDimens.space4),
                              Icon(
                                Icons.star_rounded,
                                size: AppDimens.iconSmall,
                                color: context.tokens.categoryColor(spot.category),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppDimens.space4),
                        Row(
                          children: [
                            DistancePill(
                              spot: spot,
                              showSuffix: false,
                            ),
                            const SizedBox(width: AppDimens.space8),
                            Text(
                              context.l10n.savedAgo(
                                TimeAgoFormatter.format(
                                  spot.savedAt,
                                  context.l10n,
                                ),
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _QuickDirectionsButton(
                    onPressed: () {
                      const MapsLauncher().openDirections(
                        latitude: spot.latitude,
                        longitude: spot.longitude,
                        label: spot.name,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space12),
              SpotActionsRow(
                spot: spot,
                onOpenInMaps: onOpenInMaps,
                onShare: onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickDirectionsButton extends StatelessWidget {
  const _QuickDirectionsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Material(
      color: colorScheme.primaryContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        splashColor: colorScheme.primary.withAlpha(40),
        highlightColor: colorScheme.primary.withAlpha(20),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_outward_rounded,
            size: AppDimens.iconSmall + 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
