import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/location/location_cubit.dart';
import '../cubits/location/location_state.dart';
import '../models/location_access.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import 'adaptive/adaptive_ui.dart';

/// A friendly banner displayed when location access is denied or service is disabled.
class LocationPermissionBanner extends StatelessWidget {
  const LocationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      buildWhen: (prev, curr) => prev.access != curr.access,
      builder: (context, state) {
        if (state.access == LocationAccess.granted) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final colorScheme = context.colorScheme;
        final isServiceOff = state.access == LocationAccess.serviceDisabled;
        final isDeniedForever = state.access == LocationAccess.deniedForever;

        final title = isServiceOff
            ? l10n.serviceDisabledTitle
            : l10n.permissionDeniedTitle;
        final message = isServiceOff
            ? l10n.serviceDisabledMessage
            : l10n.permissionDeniedMessage;
        final actionLabel = isServiceOff
            ? l10n.turnOn
            : (isDeniedForever ? l10n.openSettings : l10n.allow);

        return Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppDimens.space16,
          ),
          child: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: AppDimens.borderRadiusMedium,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppDimens.space12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    color: colorScheme.error,
                    size: AppDimens.iconMedium,
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: context.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          message,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  AdaptiveButton(
                    label: actionLabel,
                    style: AdaptiveButtonStyle.tinted,
                    size: AdaptiveButtonSize.small,
                    minSize: const Size(0, 36),
                    onPressed: () {
                      final cubit = context.read<LocationCubit>();
                      if (isServiceOff) {
                        cubit.openLocationSettings();
                      } else if (isDeniedForever) {
                        cubit.openAppSettings();
                      } else {
                        cubit.requestPermission();
                      }
                    },
                  ),
                ],  
              ),
            ),
          ),
        );
      },
    );
  }
}
