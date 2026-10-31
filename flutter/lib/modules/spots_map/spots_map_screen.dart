import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/app_router.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_state.dart';
import '../../shared/cubits/location/location_cubit.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/models/spot.dart';
import '../../shared/services/marker_icon_cache.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/app_map.dart';
import '../../shared/widgets/center_pin.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/pill_button.dart';
import 'cubit/spots_map_cubit.dart';
import 'cubit/spots_map_state.dart';
import 'widgets/save_spot_bottom_panel.dart';
import 'widgets/selected_spot_card.dart';

/// Route name of the details sheet. Used to close it programmatically
/// (for example when add mode ends because the spot was saved).
const String _detailsSheetRouteName = 'spots_map_details_sheet';

/// Height of the "Pick here" button.
const double _pickHereButtonHeight = 54.0;

class SpotsMapScreen extends StatelessWidget {
  const SpotsMapScreen({
    super.key,
    this.initialSpotId,
    this.initialMode = SpotsMapMode.viewing,
    this.initialTarget,
    this.initialSpotName,
    this.editingSpot,
    this.isEmbedded = false,
    this.onClose,
    this.onlyShowSpotId,
  });

  final String? initialSpotId;
  final SpotsMapMode initialMode;
  final LatLng? initialTarget;
  final String? initialSpotName;
  final Spot? editingSpot;
  final bool isEmbedded;
  final VoidCallback? onClose;
  final String? onlyShowSpotId;

  @override
  Widget build(BuildContext context) {
    final spotsCubit = context.read<SpotsCubit>();
    final locationCubit = context.read<LocationCubit>();
    final themeTokens = context.tokens;
    final isDarkMode = context.isDarkMode;

    final effectiveMode = editingSpot != null
        ? SpotsMapMode.addSpot
        : initialMode;

    return BlocProvider<SpotsMapCubit>(
      create: (_) => SpotsMapCubit(
        spotsCubit: spotsCubit,
        locationCubit: locationCubit,
        markerIconCache: MarkerIconCache(),
        themeExtension: themeTokens,
        isDarkMode: isDarkMode,
        initialSelectedSpotId: initialSpotId,
        initialTarget: editingSpot?.latLng ?? initialTarget,
        initialSpotName: editingSpot?.name ?? initialSpotName,
        editingSpot: editingSpot,
        initialMode: effectiveMode,
        onlyShowSpotId: onlyShowSpotId,
      ),
      child: _SpotsMapView(isEmbedded: isEmbedded, onClose: onClose),
    );
  }
}

class _SpotsMapView extends StatelessWidget {
  const _SpotsMapView({required this.isEmbedded, this.onClose});

  final bool isEmbedded;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    // Explicitly listen to theme brightness so entire view rebuilds on theme changes
    final _ = context.isDarkMode;

    final mediaQuery = MediaQuery.of(context);

    final view = LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        final mapHeight = constraints.maxHeight;

        final cubit = context.read<SpotsMapCubit>();
        // The pin sits at the exact center of the screen. There is no bottom panel
        // while picking, so nothing needs to be avoided.
        cubit.updatePinScreenMetrics(
          topPadding: 0,
          bottomPadding: 0,
          screenWidth: mapWidth,
          screenHeight: mapHeight,
          devicePixelRatio: mediaQuery.devicePixelRatio,
        );

        return Scaffold(
          resizeToAvoidBottomInset: false,

          body: Stack(
            children: [
              // 1. Fullscreen Map
              const _MapLayer(),

              // 2. Dark Map Loading Mask (masks native map during dark theme initialization)
              const _DarkMapLoadingMask(),

              // 3. Center Pin (only when adding a spot)
              _CenterPinLayer(pinPoint: cubit.pinScreenPoint),

              // 4. Top Floating Navigation Controls
              _TopControlsLayer(isEmbedded: isEmbedded, onClose: onClose),

              // 5. Recenter / My Location FAB
              const _RecenterButtonLayer(),

              // 6. Selected Spot Card
              const _SelectedSpotCardLayer(),

              // 7. "Pick here" button (only when adding a spot).
              //    Tapping it opens the details sheet (name, category, save).
              _PickHereBarLayer(isEmbedded: isEmbedded),
            ],
          ),
        );
      },
    );

    // Closes the details sheet when add mode ends while it is open
    // (saved successfully, or the user left add mode some other way).
    final withSheetListener = BlocListener<SpotsMapCubit, SpotsMapState>(
      listenWhen: (prev, curr) =>
          prev.isAddingSpot && !curr.isAddingSpot && prev.isDetailsSheetOpen,
      listener: (context, _) {
        Navigator.of(context)
            .popUntil((route) => route.settings.name != _detailsSheetRouteName);
      },
      child: view,
    );

    if (isEmbedded) {
      return BlocListener<AdaptiveNavCubit, AdaptiveNavState>(
        listener: (context, navState) {
          final cubit = context.read<SpotsMapCubit>();
          if (navState.detailPane == DetailPaneType.saveSpot) {
            if (navState.editingSpot != null) {
              cubit.enterEditSpotMode(navState.editingSpot!);
            } else if (!cubit.state.isAddingSpot) {
              cubit.enterAddSpotMode();
            }
          } else if (navState.detailPane == DetailPaneType.map) {
            if (cubit.state.isAddingSpot) {
              cubit.exitAddSpotMode();
            }
            if (navState.selectedSpotId != null) {
              cubit.selectSpotById(
                navState.selectedSpotId!,
                onlyShowSpot: navState.onlyShowSpot,
              );
            } else {
              cubit.selectSpot(null);
            }
          }
        },
        child: withSheetListener,
      );
    }

    return withSheetListener;
  }
}

/// Resolves the point under the pin, then opens the details sheet as a modal bottom sheet.
///
/// Cancel, swipe down and system back only close the sheet: the user goes back to
/// picking and the pin and "Pick here" button stay. Saving ends add mode, which closes
/// the sheet through the listener in [_SpotsMapView].
Future<void> _openDetailsSheet(
  BuildContext context, {
  required bool isEmbedded,
}) async {
  final cubit = context.read<SpotsMapCubit>();
  final adaptiveNav = isEmbedded ? context.read<AdaptiveNavCubit>() : null;

  final canOpen = await cubit.pickCurrentPoint();
  if (!canOpen) return;
  if (!context.mounted) {
    cubit.closeDetailsSheet();
    return;
  }

  FocusScope.of(context).unfocus();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // backgroundColor: Colors.transparent,
    elevation: 0,
    routeSettings: const RouteSettings(name: _detailsSheetRouteName),
    builder: (sheetContext) {
      return Padding(
        // Keep the sheet above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        // Fixed fraction of the screen (shrinks automatically when the keyboard opens),
        // so the category column can scroll while the Save button stays pinned.
        child: SizedBox(
          // height: MediaQuery.sizeOf(sheetContext).height * 0.9,
          child: BlocProvider<SpotsMapCubit>.value(
            value: cubit,
            child: SaveSpotBottomPanel(
              onSaved: (spot) {
                FocusScope.of(sheetContext).unfocus();
                // The sheet itself is closed by the BlocListener once add mode ends.
                adaptiveNav?.showMap(spotId: spot.id);
              },
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ),
      );
    },
  );

  // Dismissed (cancel, swipe or back): back to picking.
  cubit.closeDetailsSheet();
}

class _MapLayer extends StatelessWidget {
  const _MapLayer();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final isDark = context.isDarkMode;
    final themeTokens = context.tokens;

    cubit.updateTheme(isDarkMode: isDark, themeExtension: themeTokens);

    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) => prev.isAddingSpot != curr.isAddingSpot,
      builder: (context, state) {
        return RepaintBoundary(
          // Google Maps is declarative: markers come from the cubit's notifier.
          child: ValueListenableBuilder<Set<Marker>>(
            valueListenable: cubit.markersNotifier,
            builder: (context, markers, _) {
              return AppMap(
                // No theme-based key: AppMap updates the map style live, so
                // the map (and its controller) is no longer recreated.
                initialCameraPosition: CameraPosition(
                  target: state.initialTarget,
                  zoom: state.initialZoom,
                ),
                markers: markers,
                onMapCreated: cubit.onMapCreated,
                onMapClick: (coords) {
                  FocusScope.of(context).unfocus();
                  if (!cubit.state.isAddingSpot) {
                    cubit.selectSpot(null);
                  }
                },
                onMapLongClick: (coords) {
                  FocusScope.of(context).unfocus();
                  cubit.onMapLongClick(coords);
                },
                onCameraMove: cubit.onCameraMove,
                onCameraIdle: cubit.onCameraIdle,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
              );
            },
          ),
        );
      },
    );
  }
}

class _DarkMapLoadingMask extends StatelessWidget {
  const _DarkMapLoadingMask();

  @override
  Widget build(BuildContext context) {
    if (!context.isDarkMode) return const SizedBox.shrink();

    return BlocSelector<SpotsMapCubit, SpotsMapState, bool>(
      selector: (state) => state.isMapReady,
      builder: (context, isMapReady) {
        return IgnorePointer(
          ignoring: isMapReady,
          child: AnimatedOpacity(
            opacity: isMapReady ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: const ColoredBox(
              color: AppColors.darkMapBackground,
              child: SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _CenterPinLayer extends StatelessWidget {
  const _CenterPinLayer({required this.pinPoint});

  final Point<double> pinPoint;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) =>
          prev.mode != curr.mode ||
          prev.category != curr.category ||
          prev.isCameraMoving != curr.isCameraMoving,
      builder: (context, state) {
        if (!state.isAddingSpot) return const SizedBox.shrink();

        // Physical left is used because MapLibre coordinates (x, y) are physical Cartesian pixels within the map view.
        return Positioned(
          top: pinPoint.y,
          left: pinPoint.x,
          width: 0,
          height: 0,
          child: CenterPin(
            category: state.category,
            isCameraMoving: state.isCameraMoving,
          ),
        );
      },
    );
  }
}

class _TopControlsLayer extends StatelessWidget {
  const _TopControlsLayer({required this.isEmbedded, this.onClose});

  final bool isEmbedded;
  final VoidCallback? onClose;

  void _openFullscreen(BuildContext context, SpotsMapCubit cubit) {
    final selectedSpotId = cubit.state.selectedSpot?.id;
    final cameraTarget =
        cubit.currentCameraTarget ?? cubit.state.selectedSpot?.latLng;
    final onlyShowSpot = cubit.state.onlyShowSpotId != null;
    Navigator.of(context).pushNamed(
      AppRouter.spotsMap,
      arguments: SpotsMapArgs(
        spotId: selectedSpotId,
        initialTarget: cameraTarget,
        onlyShowSpot: onlyShowSpot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final l10n = context.l10n;

    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space16,
          AppDimens.space8,
        ),
        child: BlocSelector<SpotsMapCubit, SpotsMapState, bool>(
          selector: (state) => state.isAddingSpot,
          builder: (context, isAddingSpot) {
            if (isAddingSpot) {
              return SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleIconButton(
                      icon: const BackButtonIcon(),
                      tooltip: l10n.backTooltip,
                      onPressed: () {
                        if (cubit.state.openedToAdd &&
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
                    if (isEmbedded)
                      CircleIconButton(
                        icon: const Icon(Icons.fullscreen_rounded),
                        tooltip: l10n.fullscreen,
                        onPressed: () => _openFullscreen(context, cubit),
                      ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Row(
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

                  Row(
                    crossAxisAlignment: .end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isEmbedded)
                        _AddSpotHeaderButton(onPressed: cubit.enterAddSpotMode),
                      if (isEmbedded)
                        CircleIconButton(
                          icon: const Icon(Icons.fullscreen_rounded),
                          tooltip: l10n.fullscreen,
                          onPressed: () => _openFullscreen(context, cubit),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AddSpotHeaderButton extends StatelessWidget {
  const _AddSpotHeaderButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return PillButton(
      label: context.l10n.addSpot,
      icon: Icons.add_rounded,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space16,
      ),
      onPressed: onPressed,
    );
  }
}

class _RecenterButtonLayer extends StatelessWidget {
  const _RecenterButtonLayer();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final mediaQuery = MediaQuery.of(context);

    // While picking, keep the button above the "Pick here" bar.
    final pickBarOffset =
        _pickHereButtonHeight +
        AppDimens.space16 * 2 +
        mediaQuery.padding.bottom;

    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) =>
          prev.mode != curr.mode ||
          (prev.selectedSpot != null) != (curr.selectedSpot != null),
      builder: (context, state) {
        final isAdding = state.isAddingSpot;
        final hasSelected = state.selectedSpot != null;
        final bottomOffset = isAdding
            ? pickBarOffset
            : AppDimens.space32 + (hasSelected ? 160.0 : 0.0);

        return AnimatedPositionedDirectional(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          bottom: bottomOffset,
          end: AppDimens.space16,
          child: SafeArea(
            top: false,
            bottom: !isAdding,
            child: CircleIconButton(
              icon: Icon(
                Icons.my_location_rounded,
                color: context.colorScheme.primary,
              ),
              tooltip: context.l10n.myLocation,
              onPressed: isAdding
                  ? cubit.snapToCurrentLocation
                  : cubit.recenterOnUser,
            ),
          ),
        );
      },
    );
  }
}

class _SelectedSpotCardLayer extends StatelessWidget {
  const _SelectedSpotCardLayer();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();

    return BlocBuilder<SpotsMapCubit, SpotsMapState>(
      buildWhen: (prev, curr) =>
          prev.isAddingSpot != curr.isAddingSpot ||
          prev.selectedSpot != curr.selectedSpot,
      builder: (context, state) {
        if (state.isAddingSpot || state.selectedSpot == null) {
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

/// "Pick here" button shown at the bottom while the user is choosing a point.
class _PickHereBarLayer extends StatelessWidget {
  const _PickHereBarLayer({required this.isEmbedded});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocSelector<SpotsMapCubit, SpotsMapState, bool>(
      selector: (state) => state.isAddingSpot,
      builder: (context, isAddingSpot) {
        return PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: IgnorePointer(
            ignoring: !isAddingSpot,
            child: ExcludeSemantics(
              excluding: !isAddingSpot,
              child: AnimatedSlide(
                offset: isAddingSpot ? Offset.zero : const Offset(0, 1.5),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: isAddingSpot ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppDimens.space16,
                        0,
                        AppDimens.space16,
                        AppDimens.space16,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 300,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                _pickHereButtonHeight,
                              ),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.pin_drop_rounded),
                            label: Text(l10n.pickHere),
                            onPressed: () => _openDetailsSheet(
                              context,
                              isEmbedded: isEmbedded,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
