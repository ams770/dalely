import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_state.dart';
import '../../shared/cubits/location/location_cubit.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/services/marker_icon_cache.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/app_google_map.dart';
import '../../shared/widgets/center_pin.dart';
import '../../shared/widgets/circle_icon_button.dart';
import 'cubit/spots_map_cubit.dart';
import 'cubit/spots_map_state.dart';
import 'widgets/save_spot_bottom_panel.dart';
import 'widgets/selected_spot_card.dart';

class SpotsMapScreen extends StatelessWidget {
  const SpotsMapScreen({
    super.key,
    this.initialSpotId,
    this.initialMode = SpotsMapMode.viewing,
    this.isEmbedded = false,
    this.onClose,
  });

  final String? initialSpotId;
  final SpotsMapMode initialMode;
  final bool isEmbedded;
  final VoidCallback? onClose;

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
        initialMode: initialMode,
      ),
      child: _SpotsMapView(
        initialMode: initialMode,
        isEmbedded: isEmbedded,
        onClose: onClose,
      ),
    );
  }
}

class _SpotsMapView extends StatelessWidget {
  const _SpotsMapView({
    required this.initialMode,
    required this.isEmbedded,
    this.onClose,
  });

  final SpotsMapMode initialMode;
  final bool isEmbedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final view = Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Fullscreen Google Map
          const _MapLayer(),

          // 2. Center Pin (only when adding a spot)
          const _CenterPinLayer(),

          // 3. Top Floating Navigation Controls
          _TopControlsLayer(
            initialMode: initialMode,
            isEmbedded: isEmbedded,
            onClose: onClose,
          ),

          // 4. Recenter / My Location FAB
          const _RecenterButtonLayer(),

          // 5. Bottom Overlay: SelectedSpotCard or SaveSpotBottomPanel
          _BottomOverlayLayer(
            initialMode: initialMode,
            isEmbedded: isEmbedded,
            onClose: onClose,
          ),
        ],
      ),
    );

    if (isEmbedded) {
      return BlocListener<AdaptiveNavCubit, AdaptiveNavState>(
        listener: (context, navState) {
          final cubit = context.read<SpotsMapCubit>();
          if (navState.detailPane == DetailPaneType.saveSpot) {
            if (!cubit.state.isAddingSpot) {
              cubit.enterAddSpotMode();
            }
          } else if (navState.detailPane == DetailPaneType.map) {
            if (cubit.state.isAddingSpot) {
              cubit.exitAddSpotMode();
            }
            if (navState.selectedSpotId != null) {
              cubit.selectSpotById(navState.selectedSpotId!);
            }
          }
        },
        child: view,
      );
    }

    return view;
  }
}

class _MapLayer extends StatelessWidget {
  const _MapLayer();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 64.0;
    final bottomAddPadding = 240.0 + mediaQuery.padding.bottom;

    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) =>
          prev.markers != curr.markers || prev.mode != curr.mode,
      builder: (context, state) {
        return AppGoogleMap(
          initialCameraPosition: CameraPosition(
            target: state.initialTarget,
            zoom: state.initialZoom,
          ),
          onMapCreated: cubit.onMapCreated,
          markers: state.markers,
          onTap: (_) {
            FocusScope.of(context).unfocus();
            if (!state.isAddingSpot) {
              cubit.selectSpot(null);
            }
          },
          onCameraMoveStarted: cubit.onCameraMoveStarted,
          onCameraMove: cubit.onCameraMove,
          onCameraIdle: cubit.onCameraIdle,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: state.isAddingSpot ? bottomAddPadding : 120.0,
          ),
        );
      },
    );
  }
}

class _CenterPinLayer extends StatelessWidget {
  const _CenterPinLayer();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 64.0;
    final bottomAddPadding = 240.0 + mediaQuery.padding.bottom;

    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) =>
          prev.mode != curr.mode ||
          prev.category != curr.category ||
          prev.isCameraMoving != curr.isCameraMoving,
      builder: (context, state) {
        if (!state.isAddingSpot) return const SizedBox.shrink();

        return PositionedDirectional(
          top: topPadding,
          bottom: bottomAddPadding,
          start: 0,
          end: 0,
          child: Center(
            child: CenterPin(
              category: state.category,
              isCameraMoving: state.isCameraMoving,
            ),
          ),
        );
      },
    );
  }
}

class _TopControlsLayer extends StatelessWidget {
  const _TopControlsLayer({
    required this.initialMode,
    required this.isEmbedded,
    this.onClose,
  });

  final SpotsMapMode initialMode;
  final bool isEmbedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final l10n = context.l10n;
    final wasOpenedToAdd = initialMode == SpotsMapMode.addSpot;

    return PositionedDirectional(
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
          child: BlocSelector<SpotsMapCubit, SpotsMapState, bool>(
            selector: (state) => state.isAddingSpot,
            builder: (context, isAddingSpot) {
              if (isAddingSpot) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleIconButton(
                      icon: const BackButtonIcon(),
                      tooltip: l10n.backTooltip,
                      onPressed: () {
                        if (wasOpenedToAdd &&
                            !isEmbedded &&
                            Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        } else {
                          if (onClose != null) {
                            onClose!();
                          }
                          cubit.exitAddSpotMode();
                        }
                      },
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isEmbedded)
                    CircleIconButton(
                      icon: const BackButtonIcon(),
                      tooltip: l10n.backTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox.shrink(),
                  CircleIconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: l10n.saveThisSpot,
                    onPressed: cubit.enterAddSpotMode,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecenterButtonLayer extends StatelessWidget {
  const _RecenterButtonLayer();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final mediaQuery = MediaQuery.of(context);
    final bottomAddPadding = 240.0 + mediaQuery.padding.bottom;

    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) =>
          prev.mode != curr.mode ||
          (prev.selectedSpot != null) != (curr.selectedSpot != null),
      builder: (context, state) {
        if (state.isAddingSpot) {
          return PositionedDirectional(
            bottom: bottomAddPadding + AppDimens.space16,
            end: AppDimens.space16,
            child: CircleIconButton(
              icon: Icon(
                Icons.my_location_rounded,
                color: context.colorScheme.primary,
              ),
              tooltip: context.l10n.myLocation,
              onPressed: cubit.snapToCurrentLocation,
            ),
          );
        }

        final hasSelected = state.selectedSpot != null;
        return PositionedDirectional(
          bottom: AppDimens.space32,
          end: AppDimens.space16,
          child: SafeArea(
            top: false,
            child: Padding(
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
            ),
          ),
        );
      },
    );
  }
}

class _BottomOverlayLayer extends StatelessWidget {
  const _BottomOverlayLayer({
    required this.initialMode,
    required this.isEmbedded,
    this.onClose,
  });

  final SpotsMapMode initialMode;
  final bool isEmbedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final wasOpenedToAdd = initialMode == SpotsMapMode.addSpot;

    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) =>
          prev.mode != curr.mode || prev.selectedSpot != curr.selectedSpot,
      builder: (context, state) {
        if (state.isAddingSpot) {
          return PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: SaveSpotBottomPanel(
              onSaved: (spot) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.spotSaved(spot.name)),
                    duration: const Duration(seconds: 3),
                  ),
                );

                if (onClose != null) {
                  onClose!();
                } else if (wasOpenedToAdd &&
                    !isEmbedded &&
                    Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
            ),
          );
        }

        if (state.selectedSpot == null) {
          return const SizedBox.shrink();
        }

        return PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDimens.space16,
                0,
                AppDimens.space16,
                AppDimens.space16,
              ),
              child: SelectedSpotCard(
                spot: state.selectedSpot!,
                onClose: () => cubit.selectSpot(null),
              ),
            ),
          ),
        );
      },
    );
  }
}
