import 'package:flutter/material.dart';

import '../models/spot.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
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
                                color: context.tokens.categoryColor(
                                  spot.category,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  DistancePill(spot: spot, showSuffix: false),
                ],
              ),
              Divider(height: AppDimens.space24),
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
