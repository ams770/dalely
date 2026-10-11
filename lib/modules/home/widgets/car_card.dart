import 'package:feen/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/app_assets.dart';
import '../../../shared/utils/adaptive_navigation.dart';
import '../../../shared/cubits/car_tracking/car_tracking_cubit.dart';
import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/settings/settings_cubit.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/cubits/spots/spots_state.dart';
import '../../../shared/models/location_access.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/maps_launcher.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/car_tracking_calculator.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/info_pill.dart';
import '../cubit/parking_timer_cubit.dart';
import '../cubit/parking_timer_state.dart';

/// The car card shown at the top of the Home screen.
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
            padding: const EdgeInsetsDirectional.all(AppDimens.space20),
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
    AdaptiveNavigation.openMap(context, spotId: car.id);
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
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.carTrackingTooFar),
                duration: const Duration(seconds: 3),
              ),
            );
            AdaptiveNavigation.openMap(context, spotId: car.id);
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
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(l10n.carCleared),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () {
              spotsCubit.restoreSpot(car);
            },
          ),
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
        ScaffoldMessenger.of(context).clearSnackBars();

        if (access == LocationAccess.serviceDisabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.serviceDisabledMessage),
              action: SnackBarAction(
                label: l10n.turnOn,
                onPressed: locationCubit.openLocationSettings,
              ),
            ),
          );
        } else if (access == LocationAccess.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.permissionDeniedMessage),
              action: SnackBarAction(
                label: l10n.openSettings,
                onPressed: locationCubit.openAppSettings,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.locationUnavailable)));
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

    return Column(
      crossAxisAlignment: .center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: .center,
                children: [
                  FittedBox(
                    child: DistancePill(
                      spot: car,
                      backgroundColor: primary.withAlpha(15),
                      foregroundColor: primary,
                      showIcon: false,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppDimens.space12,
                        vertical: AppDimens.space6,
                      ),
                      textStyle: context.textTheme.headlineSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space6),
                  _ParkingTimer(savedAt: car.savedAt),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            const Expanded(
              flex: 6,
              child: SizedBox(
                height: AppDimens.carImageHeight,
                child: Image(
                  image: AssetProvider.carImage,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            CircleIconButton(
              icon: Icon(
                Icons.map_outlined,
                color: primary,
                size: AppDimens.iconSmall,
              ),
              size: AppDimens.minTouchTarget,
              backgroundColor: primary.withAlpha(14),
              border: Border.all(color: primary.withAlpha(80)),
              tooltip: l10n.onMap,
              onPressed: onOpenInMaps,
            ),
            const SizedBox(width: AppDimens.space6),
            CircleIconButton(
              icon: Icon(
                Icons.share_outlined,
                color: primary,
                size: AppDimens.iconSmall,
              ),
              size: AppDimens.minTouchTarget,
              backgroundColor: primary.withAlpha(14),
              border: Border.all(color: primary.withAlpha(80)),
              tooltip: l10n.share,
              onPressed: onShare,
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              flex: 5,
              child: _PillButton(
                label: l10n.whereMyCarTitle,
                icon: Icons.navigation_rounded,
                backgroundColor: primary,
                foregroundColor: colors.onPrimary,
                onPressed: onShowOnMap,
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            Expanded(
              flex: 5,
              child: _PillButton(
                label: l10n.foundMyCar,
                icon: Icons.check_circle_outline_rounded,
                backgroundColor: AppColors.greenLight,
                foregroundColor: AppColors.greenDark,
                onPressed: onFoundCar,
              ),
            ),
          ],
        ),
      ],
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
            children: [
              Icon(
                Icons.schedule_rounded,
                size: AppDimens.iconSmall,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppDimens.space4),
              Expanded(
                child: FittedBox(
                  child: Text(
                    l10n.parkedAgo(state.formattedElapsed),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noCarTitle,
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    l10n.noCarMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: .end,
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Expanded(
                        child: _PillButton(
                          label: l10n.parkHere,
                          // icon: Icons.add_location_alt_rounded,
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          onPressed: onPark,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space32),
                      const SizedBox(
                        width: AppDimens.carImageSize,
                        child: Image(
                          image: AssetProvider.carImage,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.minTouchTarget,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppDimens.borderRadiusFull,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppDimens.borderRadiusFull,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppDimens.borderRadiusFull,
            splashColor: foregroundColor.withAlpha(25),
            highlightColor: foregroundColor.withAlpha(15),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: AppDimens.iconSmall,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: AppDimens.space6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
