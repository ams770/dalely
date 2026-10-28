import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/app_assets.dart';
import '../../../shared/cubits/car_tracking/car_tracking_cubit.dart';
import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/settings/settings_cubit.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/cubits/spots/spots_state.dart';
import '../../../shared/models/location_access.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/maps_launcher.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/adaptive_layout_ext.dart';
import '../../../shared/utils/adaptive_navigation.dart';
import '../../../shared/utils/app_snack_bar.dart';
import '../../../shared/utils/car_tracking_calculator.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/info_pill.dart';
import '../../../shared/widgets/pill_button.dart';
import '../cubit/parking_timer_cubit.dart';
import '../cubit/parking_timer_state.dart';

/// The car card shown in the 2-column home grid.
///
/// Uses [AnimatedCrossFade] to smoothly transition between the unparked
/// prompt and active parked status, with all styling derived from the theme.
class CarCard extends StatelessWidget {
  const CarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) => prev.car != curr.car,
      builder: (context, state) {
        final car = state.car;
        final hasCar = car != null;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppDimens.borderRadiusLarge,
            border: Border.all(color: colors.outlineVariant.withAlpha(100)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: AppDimens.space20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDimens.space16),
            child: AnimatedCrossFade(
              duration: AppDimens.animDurationMedium,
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
              sizeCurve: Curves.easeInOut,
              crossFadeState: hasCar
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _EmptyCarContent(onPark: () => _handlePark(context)),
              secondChild: car != null
                  ? _ActiveCarContent(
                      car: car,
                      onShowOnMap: () => _handleShowOnMap(context, car),
                      onOpenInMaps: () => _handleOpenInMaps(context, car),
                      onShare: () => _handleShare(context, car),
                      onFoundCar: () => _handleFoundCar(context, car),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  void _handleShowOnMap(BuildContext context, Spot car) {
    AdaptiveNavigation.openMap(context, spotId: car.id, onlyShowSpot: true);
  }

  void _handleOpenInMaps(BuildContext context, Spot car) async {
    final l10n = context.l10n;
    final settings = context.read<SettingsCubit>().state;
    final trackingCubit = context.read<CarTrackingCubit>();
    final locationCubit = context.read<LocationCubit>();
    final pos = locationCubit.state.latLng;

    if (settings.carDistanceNotificationEnabled) {
      if (pos != null) {
        final dist = CarTrackingCalculator.calculateDistance(
          startLatitude: pos.latitude,
          startLongitude: pos.longitude,
          endLatitude: car.latitude,
          endLongitude: car.longitude,
        );
        if (CarTrackingCalculator.isTooFar(dist)) {
          if (context.mounted) {
            AppSnackBar.show(context, content: Text(l10n.carTrackingTooFar));
            AdaptiveNavigation.openMap(
              context,
              spotId: car.id,
              onlyShowSpot: true,
            );
          }
          return;
        }
      }

      await trackingCubit.startCarTracking(
        car: car,
        currentLat: pos?.latitude,
        currentLng: pos?.longitude,
        isArabic: context.isArabic,
      );
    }

    const MapsLauncher().openDirections(
      latitude: car.latitude,
      longitude: car.longitude,
      label: car.name,
    );
  }

  void _handleShare(BuildContext context, Spot car) {
    const ShareService().shareSpot(car, l10n: context.l10n);
  }

  void _handleFoundCar(BuildContext context, Spot car) async {
    final spotsCubit = context.read<SpotsCubit>();
    final trackingCubit = context.read<CarTrackingCubit>();
    final l10n = context.l10n;

    await trackingCubit.stopCarTracking();
    await spotsCubit.clearCar();
    if (context.mounted) {
      AppSnackBar.show(
        context,
        content: Text(l10n.carCleared),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            spotsCubit.restoreSpot(car);
          },
        ),
      );
    }
  }

  void _handlePark(BuildContext context) async {
    final locationCubit = context.read<LocationCubit>();
    final spotsCubit = context.read<SpotsCubit>();
    final trackingCubit = context.read<CarTrackingCubit>();
    final l10n = context.l10n;

    await trackingCubit.stopCarTracking();
    final pos = await locationCubit.getOrAcquirePosition();
    if (!context.mounted) return;

    if (pos != null) {
      await spotsCubit.parkCar(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } else {
      if (context.mounted) {
        final access = locationCubit.state.access;

        if (access == LocationAccess.serviceDisabled) {
          AppSnackBar.show(
            context,
            content: Text(l10n.serviceDisabledMessage),
            action: SnackBarAction(
              label: l10n.turnOn,
              onPressed: locationCubit.openLocationSettings,
            ),
          );
        } else if (access == LocationAccess.deniedForever) {
          AppSnackBar.show(
            context,
            content: Text(l10n.permissionDeniedMessage),
            action: SnackBarAction(
              label: l10n.openSettings,
              onPressed: locationCubit.openAppSettings,
            ),
          );
        } else {
          AppSnackBar.show(context, content: Text(l10n.locationUnavailable));
        }
      }
    }
  }
}

class _ActiveCarContent extends StatelessWidget {
  const _ActiveCarContent({
    required this.car,
    required this.onShowOnMap,
    required this.onOpenInMaps,
    required this.onShare,
    required this.onFoundCar,
  });

  final Spot car;
  final VoidCallback onShowOnMap;
  final VoidCallback onOpenInMaps;
  final VoidCallback onShare;
  final VoidCallback onFoundCar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colorScheme;
    final primary = colors.primary;

    var content = context.isSplitLayout
        ? [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 68,
                    child: Image(
                      image: AssetProvider.carImage,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                  Expanded(child: _ParkingTimer(savedAt: car.savedAt)),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),
            Row(
              spacing: AppDimens.space6,
              children: [
                Expanded(
                  child: PillButton(
                    style: .tinted,
                    label: l10n.openMap,
                    icon: Icons.navigation_rounded,
                    backgroundColor: primary,
                    foregroundColor: colors.onPrimary,
                    onPressed: onShowOnMap,
                  ),
                ),
                Expanded(
                  child: PillButton(
                    style: .tinted,
                    label: ' ${l10n.foundMyCar}  ',
                    icon: Icons.check_circle_outline_rounded,
                    backgroundColor: AppColors.greenLight,
                    foregroundColor: AppColors.greenDark,
                    onPressed: onFoundCar,
                  ),
                ),
              ],
            ),
          ]
        : [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 48,
                    child: Image(
                      image: AssetProvider.carImage,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space4),
                  _ParkingTimer(savedAt: car.savedAt),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PillButton(
                  style: .tinted,
                  label: l10n.openMap,
                  icon: Icons.navigation_rounded,
                  backgroundColor: primary,
                  foregroundColor: colors.onPrimary,
                  onPressed: onShowOnMap,
                ),
                const SizedBox(height: AppDimens.space6),
                PillButton(
                  style: .tinted,
                  label: ' ${l10n.foundMyCar}  ',
                  icon: Icons.check_circle_outline_rounded,
                  backgroundColor: AppColors.greenLight,
                  foregroundColor: AppColors.greenDark,
                  onPressed: onFoundCar,
                ),
              ],
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: DistancePill(
                  spot: car,
                  backgroundColor: primary.withAlpha(15),
                  foregroundColor: primary,
                  showIcon: false,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppDimens.space8,
                    vertical: AppDimens.space4,
                  ),
                  textStyle: context.textTheme.titleMedium?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CarMiniActionButton(
                  icon: Icons.history_rounded,
                  tooltip: l10n.parkingHistory,
                  onPressed: () =>
                      AdaptiveNavigation.openParkingHistory(context),
                ),
                const SizedBox(width: AppDimens.space4),
                _CarMiniActionButton(
                  icon: Icons.share_outlined,
                  tooltip: l10n.share,
                  onPressed: onShare,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space8),

        ...content,
      ],
    );
  }
}

class _CarMiniActionButton extends StatelessWidget {
  const _CarMiniActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.primary.withAlpha(14),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: AppDimens.iconSmall, color: colors.primary),
          ),
        ),
      ),
    );
  }
}

class _ParkingTimer extends StatelessWidget {
  const _ParkingTimer({required this.savedAt});

  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final l10n = context.l10n;

    return BlocProvider<ParkingTimerCubit>(
      key: ValueKey(savedAt.millisecondsSinceEpoch),
      create: (_) => ParkingTimerCubit(savedAt: savedAt),
      child: BlocBuilder<ParkingTimerCubit, ParkingTimerState>(
        buildWhen: (prev, curr) =>
            prev.elapsed.inSeconds != curr.elapsed.inSeconds,
        builder: (context, state) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: .center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: AppDimens.iconSmall,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppDimens.space4),
              Text(
                l10n.parkedAgo(state.formattedElapsed),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: context.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCarContent extends StatelessWidget {
  const _EmptyCarContent({required this.onPark});

  final VoidCallback onPark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colorScheme;

    var content = context.isSplitLayout
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 68,
                child: Image(
                  image: AssetProvider.carImage,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),

              const Spacer(),

              PillButton(
                style: .tinted,
                label: l10n.parkHere,
                icon: Icons.local_parking_rounded,
                backgroundColor: colors.primary.withAlpha(18),
                foregroundColor: Colors.blueAccent,
                onPressed: onPark,
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 52,
                child: Image(
                  image: AssetProvider.carImage,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              Text(
                l10n.noCarMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                l10n.myCar,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _CarMiniActionButton(
              icon: Icons.history_rounded,
              tooltip: l10n.parkingHistory,
              onPressed: () => AdaptiveNavigation.openParkingHistory(context),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space8),
        Center(child: content),
        if (!context.isSplitLayout) ...[
          const SizedBox(height: AppDimens.space8),
          PillButton(
            label: l10n.parkHere,
            icon: Icons.local_parking_rounded,
            backgroundColor: colors.primary.withAlpha(18),
            foregroundColor: colors.primary,
            style: .tinted,
            onPressed: onPark,
          ),
        ],
      ],
    );
  }
}
