import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../shared/cubits/location/location_cubit.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/cubits/spots/spots_state.dart';
import '../../shared/models/spot.dart';
import '../../shared/services/marker_icon_cache.dart';
import '../../shared/services/share_service.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/app_google_map.dart';
import '../../shared/widgets/circle_icon_button.dart';
import 'cubit/spots_map_cubit.dart';
import 'cubit/spots_map_state.dart';
import 'widgets/selected_spot_card.dart';

class SpotsMapScreen extends StatelessWidget {
  const SpotsMapScreen({
    super.key,
    this.initialSpotId,
  });

  final String? initialSpotId;

  @override
  Widget build(BuildContext context) {
    final spotsCubit = context.read<SpotsCubit>();
    final locationCubit = context.read<LocationCubit>();
    final themeTokens = context.tokens;

    return BlocProvider<SpotsMapCubit>(
      create: (_) => SpotsMapCubit(
        spotsCubit: spotsCubit,
        locationCubit: locationCubit,
        markerIconCache: MarkerIconCache(),
        themeExtension: themeTokens,
        initialSelectedSpotId: initialSpotId,
      ),
      child: const _SpotsMapView(),
    );
  }
}

class _SpotsMapView extends StatelessWidget {
  const _SpotsMapView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();

    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Google Map
          BlocBuilder<SpotsMapCubit, SpotsMapState>(
            buildWhen: (prev, curr) => prev.markers != curr.markers,
            builder: (context, state) {
              return AppGoogleMap(
                initialCameraPosition: CameraPosition(
                  target: state.initialTarget,
                  zoom: state.initialZoom,
                ),
                onMapCreated: cubit.onMapCreated,
                markers: state.markers,
                onTap: (_) => cubit.selectSpot(null),
                onCameraMove: cubit.onCameraMove,
                onCameraIdle: cubit.onCameraIdle,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                padding: const EdgeInsets.only(
                  top: 100,
                  bottom: 120,
                ),
              );
            },
          ),

          // Top Header Floating Controls
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space16,
                  vertical: AppDimens.space8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleIconButton(
                      icon: const BackButtonIcon(),
                      tooltip: context.l10n.backTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const _ShareAllHeaderButton(),
                  ],
                ),
              ),
            ),
          ),

          // Re-center FAB
          PositionedDirectional(
            bottom: AppDimens.space32,
            end: AppDimens.space16,
            child: SafeArea(
              top: false,
              child: BlocSelector<SpotsMapCubit, SpotsMapState, bool>(
                selector: (state) => state.selectedSpot != null,
                builder: (context, hasSelected) {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: hasSelected ? 160.0 : 0.0,
                    ),
                    child: CircleIconButton(
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: context.colorScheme.primary,
                      ),
                      tooltip: context.l10n.myLocation,
                      onPressed: cubit.recenterOnUser,
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Selected Spot Card Overlay
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              top: false,
              child: BlocSelector<SpotsMapCubit, SpotsMapState, Spot?>(
                selector: (state) => state.selectedSpot,
                builder: (context, spot) {
                  if (spot == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppDimens.space16,
                      0,
                      AppDimens.space16,
                      AppDimens.space16,
                    ),
                    child: SelectedSpotCard(
                      spot: spot,
                      onClose: () => cubit.selectSpot(null),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareAllHeaderButton extends StatelessWidget {
  const _ShareAllHeaderButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotsCubit, SpotsState>(
      builder: (context, spotsState) {
        if (spotsState.allSpots.isEmpty) return const SizedBox.shrink();

        return Material(
          color: context.colorScheme.primary,
          borderRadius: AppDimens.borderRadiusFull,
          elevation: 3,
          shadowColor: context.colorScheme.primary.withAlpha(90),
          child: InkWell(
            onTap: () {
              const ShareService().shareAllSpots(
                spotsState.allSpots,
                l10n: context.l10n,
              );
            },
            borderRadius: AppDimens.borderRadiusFull,
            child: Container(
              height: AppDimens.iconButtonSize,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space16,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ios_share_rounded,
                    size: AppDimens.iconSmall,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Text(
                    context.l10n.shareAll,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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
