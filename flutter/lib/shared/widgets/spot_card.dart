import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/spot_categories.dart';
import '../cubits/spots/spots_cubit.dart';
import '../models/spot.dart';
import '../services/maps_launcher.dart';
import '../services/share_service.dart';
import '../theme/app_dimens.dart';
import '../utils/adaptive_navigation.dart';
import '../utils/app_snack_bar.dart';
import '../utils/context_ext.dart';
import '../utils/time_ago_formatter.dart';
import 'category_badge.dart';
import 'info_pill.dart';
import 'spot_adaptive_menu.dart';

/// A simplified, modern card representing a saved spot showing only key details.
/// Actions are revealed adaptively on long-press or via the menu button.
class SpotCard extends StatelessWidget {
  const SpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.onLongPress,
    this.onShowOnMap,
    this.onOpenInMaps,
    this.onShare,
    this.onEdit,
    this.onToggleFavorite,
    this.onDelete,
    this.isFavorite = false,
    this.showMenuButton = false,
  });

  final Spot spot;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onShowOnMap;
  final VoidCallback? onOpenInMaps;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;
  final bool isFavorite;
  final bool showMenuButton;

  VoidCallback _effectiveShare(BuildContext context) =>
      onShare ?? () => const ShareService().shareSpot(spot, l10n: context.l10n);

  VoidCallback _effectiveEdit(BuildContext context) =>
      onEdit ?? () => AdaptiveNavigation.openEditSpot(context, spot);

  VoidCallback _effectiveOpenInMaps() =>
      onOpenInMaps ??
      () => const MapsLauncher().openDirections(
            latitude: spot.latitude,
            longitude: spot.longitude,
            label: spot.name,
          );

  VoidCallback _effectiveDelete(BuildContext context) =>
      onDelete ??
      () {
        SpotsCubit? spotsCubit;
        try {
          spotsCubit = context.read<SpotsCubit>();
        } catch (_) {}
        if (spotsCubit != null) {
          final l10n = context.l10n;
          spotsCubit.deleteSpot(spot.id);
          AppSnackBar.show(
            context,
            content: Text(l10n.spotDeleted(spot.name)),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () {
                spotsCubit?.restoreSpot(spot);
              },
            ),
          );
        }
      };


  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final timeAgo = TimeAgoFormatter.format(spot.savedAt, l10n);
    final categoryLabel = spot.category.label(context);

    return Builder(
      builder: (cardContext) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: AppDimens.borderRadiusLarge,
          onTap: () {
            Feedback.forTap(cardContext);
            (onShowOnMap ?? onTap)?.call();
          },
          onLongPress: () {
            Feedback.forLongPress(cardContext);
            if (onLongPress != null) {
              onLongPress!();
            } else {
              SpotAdaptiveMenu.show(
                context: cardContext,
                spot: spot,
                onShare: _effectiveShare(cardContext),
                onEdit: _effectiveEdit(cardContext),
                onOpenInMaps: _effectiveOpenInMaps(),
                onDelete: _effectiveDelete(cardContext),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppDimens.space16,
              AppDimens.space12,
              AppDimens.space12,
              AppDimens.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Category icon badge
                CategoryBadge(category: spot.category),
                const SizedBox(width: AppDimens.space12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (isFavorite) ...[
                            const SizedBox(width: AppDimens.space6),
                            Icon(
                              Icons.star_rounded,
                              size: AppDimens.iconSmall,
                              color:
                                  context.tokens.categoryColor(spot.category),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        '$categoryLabel · $timeAgo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.space8),

                // Live distance indicator
                DistancePill(spot: spot, showSuffix: false),

                // Adaptive menu trigger button
                if (showMenuButton) ...[
                  const SizedBox(width: AppDimens.space4),
                  SpotAdaptiveMenuButton(
                    spot: spot,
                    onShare: _effectiveShare(cardContext),
                    onEdit: _effectiveEdit(cardContext),
                    onOpenInMaps: _effectiveOpenInMaps(),
                    onDelete: _effectiveDelete(cardContext),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
