import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/app_assets.dart';
import '../../../shared/constants/spot_categories.dart';
import '../../../shared/cubits/car_tracking/car_tracking_cubit.dart';
import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/settings/settings_cubit.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/maps_launcher.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/utils/car_tracking_calculator.dart';
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
      color: context.isDarkMode ? theme.scaffoldBackgroundColor : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDimens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (spot.isCar)
                  const _SelectedCarBadge()
                else
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
                if (spot.isCar) {
                  final settings = context.read<SettingsCubit>().state;
                  if (settings.carDistanceNotificationEnabled) {
                    final pos = context.read<LocationCubit>().state.latLng;
                    if (pos != null) {
                      final dist = CarTrackingCalculator.calculateDistance(
                        startLatitude: pos.latitude,
                        startLongitude: pos.longitude,
                        endLatitude: spot.latitude,
                        endLongitude: spot.longitude,
                      );
                      if (CarTrackingCalculator.isTooFar(dist)) {
                        AppSnackBar.show(
                          context,
                          content: Text(context.l10n.carTrackingTooFar),
                        );
                        return;
                      }
                    }
                    context.read<CarTrackingCubit>().startCarTracking(
                          car: spot,
                          currentLat: pos?.latitude,
                          currentLng: pos?.longitude,
                          isArabic: context.isArabic,
                        );
                  }
                }

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

class _SelectedCarBadge extends StatelessWidget {
  const _SelectedCarBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = context.isDarkMode;
    final carColor = tokens.categoryColor(SpotCategory.car);

    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(AppDimens.space6),
      decoration: BoxDecoration(
        color: carColor.withAlpha(isDark ? 50 : 35),
        borderRadius: AppDimens.borderRadiusMedium,
        border: Border.all(
          color: carColor.withAlpha(isDark ? 100 : 180),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: carColor.withAlpha(isDark ? 25 : 45),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Image(
        image: AssetProvider.carImage,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}


