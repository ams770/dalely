import 'package:flutter/material.dart';

import '../../../shared/models/spot.dart';
import '../../../shared/services/maps_launcher.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/category_badge.dart';
import '../../../shared/widgets/info_pill.dart';
import '../../../shared/widgets/spot_actions_row.dart';

/// Overlay card shown at the bottom of the map when a spot marker is selected.
class SelectedSpotCard extends StatelessWidget {
  const SelectedSpotCard({
    super.key,
    required this.spot,
    required this.onClose,
  });

  final Spot spot;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Card(
      elevation: 6,
      shadowColor: Colors.black.withAlpha(80),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDimens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryBadge(category: spot.category),
                const SizedBox(width: AppDimens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.isCar ? context.l10n.myCar : spot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space4),
                      DistancePill(spot: spot),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),
            SpotActionsRow(
              spot: spot,
              showOnMapAction: false,
              onOpenInMaps: () {
                const MapsLauncher().openDirections(
                  latitude: spot.latitude,
                  longitude: spot.longitude,
                  label: spot.name,
                );
              },
              onShare: () {
                const ShareService().shareSpot(spot, l10n: context.l10n);
              },
            ),
          ],
        ),
      ),
    );
  }
}
