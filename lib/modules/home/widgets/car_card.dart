import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_router.dart';
import '../../../shared/constants/app_assets.dart';
import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/cubits/spots/spots_state.dart';
import '../../../shared/models/location_access.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/utils/time_ago_formatter.dart';
import '../../../shared/widgets/info_pill.dart';

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
            border: Border.all(
              color: colors.outlineVariant.withAlpha(100),
            ),
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
              firstChild: _EmptyCarContent(
                onPark: () => _handlePark(context),
              ),
              secondChild: car != null
                  ? _ActiveCarContent(
                      car: car,
                      onShowOnMap: () => _handleShowOnMap(context, car),
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
    Navigator.of(context).pushNamed(AppRouter.spotsMap, arguments: car.id);
  }

  void _handleShare(BuildContext context, Spot car) {
    const ShareService().shareSpot(car, l10n: context.l10n);
  }

  void _handleFoundCar(BuildContext context, Spot car) async {
    final spotsCubit = context.read<SpotsCubit>();
    final l10n = context.l10n;

    await spotsCubit.clearCar();
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
    final l10n = context.l10n;

    final pos = await locationCubit.getOrAcquirePosition();
    if (!context.mounted) return;

    if (pos != null) {
      await spotsCubit.parkCar(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.carSaved)),
        );
      }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationUnavailable)),
          );
        }
      }
    }
  }
}

class _ActiveCarContent extends StatelessWidget {
  const _ActiveCarContent({
    required this.car,
    required this.onShowOnMap,
    required this.onShare,
    required this.onFoundCar,
  });

  final Spot car;
  final VoidCallback onShowOnMap;
  final VoidCallback onShare;
  final VoidCallback onFoundCar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colorScheme;
    final primary = colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DistancePill(
                    spot: car,
                    backgroundColor: primary.withAlpha(15),
                    foregroundColor: primary,
                    showIcon: false,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppDimens.space12,
                      vertical: AppDimens.space6,
                    ),
                    textStyle: context.textTheme.titleLarge?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space6),
                  Text(
                    l10n.parkedAgo(TimeAgoFormatter.format(car.savedAt, l10n)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
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
          ],
        ),
        const SizedBox(height: AppDimens.space16),
        Row(
          children: [
            Expanded(
              flex: 6,
              child: _PillButton(
                label: l10n.onMap,
                icon: Icons.map_rounded,
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
                backgroundColor: primary.withAlpha(14),
                foregroundColor: primary,
                onPressed: onFoundCar,
              ),
            ),
          ],
        ),
      ],
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
                  const SizedBox(height: AppDimens.space16),
                  _PillButton(
                    label: l10n.parkHere,
                    icon: Icons.add_location_alt_rounded,
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    onPressed: onPark,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            const SizedBox(
              width: AppDimens.carImageSize,
              height: AppDimens.carImageSize,
              child: Image(
                image: AssetProvider.carImage,
                fit: BoxFit.contain,
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

