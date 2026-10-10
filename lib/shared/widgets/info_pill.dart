import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/location/location_cubit.dart';
import '../cubits/location/location_state.dart';
import '../models/spot.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import '../utils/distance_formatter.dart';

/// A small pill displaying an icon and text on a neutral or custom surface.
class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.textStyle,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.tokens.pillBackground;
    final fg = foregroundColor ?? context.tokens.pillForeground;

    return Container(
      padding: padding ??
          const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space12,
            vertical: AppDimens.space4,
          ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppDimens.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppDimens.iconSmall,
              color: fg,
            ),
            const SizedBox(width: AppDimens.space4),
          ],
          Text(
            label,
            style: textStyle ??
                context.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// A specialized [InfoPill] that calculates and displays live distance to a [Spot].
///
/// Uses [BlocSelector] to rebuild narrowly only when user position changes.
class DistancePill extends StatelessWidget {
  const DistancePill({
    super.key,
    required this.spot,
    this.backgroundColor,
    this.foregroundColor,
    this.showSuffix = true,
    this.showIcon = true,
    this.padding,
    this.textStyle,
  });

  final Spot spot;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showSuffix;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LocationCubit, LocationState, double?>(
      selector: (state) {
        final pos = state.position;
        if (pos == null) return null;
        return DistanceFormatter.calculateDistance(
          startLatitude: pos.latitude,
          startLongitude: pos.longitude,
          endLatitude: spot.latitude,
          endLongitude: spot.longitude,
        );
      },
      builder: (context, distanceMeters) {
        if (distanceMeters == null) {
          return const SizedBox.shrink();
        }

        final distanceStr = DistanceFormatter.format(
          distanceMeters,
          context.l10n,
        );
        final label = showSuffix
          ? context.l10n.distanceAway(distanceStr)
          : distanceStr;

        return InfoPill(
          label: label,
          icon: showIcon ? Icons.near_me_rounded : null,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding,
          textStyle: textStyle,
        );
      },
    );
  }
}
