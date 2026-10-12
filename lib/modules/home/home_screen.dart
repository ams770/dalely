import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/constants/app_assets.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_state.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/cubits/spots/spots_state.dart';
import '../../shared/models/spot.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/adaptive_layout_ext.dart';
import '../../shared/utils/adaptive_navigation.dart';
import '../../shared/utils/app_snack_bar.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/car_proximity_listener.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/location_permission_banner.dart';
import '../../shared/widgets/primary_bottom_button.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/spot_card.dart';
import '../search/search_spots_screen.dart';
import '../settings/settings_screen.dart';
import '../spots_map/spots_map_screen.dart';
import 'widgets/car_card.dart';
import 'widgets/export_spots_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/home_map_card.dart';
import 'widgets/rename_spot_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarProximityListener(
      child: context.isWideScreen
          ? const _AdaptiveTwoPaneHome()
          : const _HomePane(),
    );
  }
}

class _AdaptiveTwoPaneHome extends StatelessWidget {
  const _AdaptiveTwoPaneHome();

  @override
  Widget build(BuildContext context) {
    final isFoldable = context.isFoldableDevice;
    final size = MediaQuery.sizeOf(context);
    final features = MediaQuery.displayFeaturesOf(context);

    // Check for a physical vertical hinge with a gap (e.g. dual-screen devices)
    DisplayFeature? verticalHinge;
    for (final f in features) {
      if ((f.type == DisplayFeatureType.hinge ||
              f.type == DisplayFeatureType.fold) &&
          f.bounds.top <= 0 &&
          f.bounds.bottom >= size.height &&
          f.bounds.width > 1) {
        verticalHinge = f;
        break;
      }
    }

    final theme = context.theme;

    if (verticalHinge != null) {
      return Material(
        color: theme.scaffoldBackgroundColor,
        child: Row(
          children: [
            SizedBox(
              width: verticalHinge.bounds.left,
              child: const _HomePane(),
            ),
            SizedBox(width: verticalHinge.bounds.width),
            SizedBox(
              width: size.width - verticalHinge.bounds.right,
              child: const _AdaptiveDetailPane(),
            ),
          ],
        ),
      );
    }

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          // Left Pane: Home
          // On foldable/flip devices, each part takes exactly half (50%) of the device.
          // On tablets, home pane is a fixed sidebar so the map takes the largest area.
          if (isFoldable)
            const Expanded(flex: 1, child: _HomePane())
          else
            const SizedBox(width: 380.0, child: _HomePane()),

          // Professional Adaptive Pane Separator
          const _AdaptivePaneSeparator(),

          // Right Pane: Active Detail (Map by default, or Settings, SaveSpot, Search)
          // On tablets, takes all remaining space (the largest area).
          // On foldable/flip devices, takes the second half (50%).
          const Expanded(flex: 1, child: _AdaptiveDetailPane()),
        ],
      ),
    );
  }
}

class _AdaptivePaneSeparator extends StatelessWidget {
  const _AdaptivePaneSeparator();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = context.isDarkMode;

    final borderColor = isDark
        ? AppColors.darkBorder
        : theme.colorScheme.outlineVariant.withAlpha(140);
    final handleColor = isDark
        ? theme.colorScheme.primary.withAlpha(200)
        : theme.colorScheme.primary.withAlpha(140);

    return Container(
      width: 12.0,
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical divider line
          Container(width: 1.0, color: borderColor),
          // Refined split affordance pill indicator
          Container(
            width: 4.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: AppDimens.borderRadiusFull,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveDetailPane extends StatelessWidget {
  const _AdaptiveDetailPane();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdaptiveNavCubit>();

    return BlocBuilder<AdaptiveNavCubit, AdaptiveNavState>(
      builder: (context, state) {
        return Stack(
          children: [
            // The single persistent Map across the entire app
            SpotsMapScreen(
              key: const ValueKey('persistent_spots_map'),
              isEmbedded: true,
              onClose: cubit.closeDetail,
            ),

            // Settings overlay
            if (state.detailPane == DetailPaneType.settings)
              Positioned.fill(child: SettingsScreen(onClose: cubit.closeDetail))
            // Search overlay
            else if (state.detailPane == DetailPaneType.search)
              Positioned.fill(
                child: SearchSpotsScreen(
                  onClose: cubit.closeDetail,
                  onSpotSelected: (id) => cubit.showMap(spotId: id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomePane extends StatelessWidget {
  const _HomePane();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: mainScaffoldMessengerKey,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const HomeHeader(),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppDimens.space16,
                        AppDimens.space8,
                        AppDimens.space16,
                        AppDimens.space16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          const LocationPermissionBanner(),
                          const _HomeCardsGrid(),
                          const SizedBox(height: AppDimens.space24),
                          const _SavedSpotsSectionHeader(),
                        ]),
                      ),
                    ),
                    const _SavedSpotsSliverList(),
                    const _BottomListSpacer(),
                  ],
                ),
              ),
              const _BottomSaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCardsGrid extends StatelessWidget {
  const _HomeCardsGrid();

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: CarCard()),
          SizedBox(width: AppDimens.space12),
          Expanded(child: HomeMapCard()),
        ],
      ),
    );
  }
}

class _BottomListSpacer extends StatelessWidget {
  const _BottomListSpacer();

  @override
  Widget build(BuildContext context) {
    if (context.isWideScreen) {
      return const SliverToBoxAdapter(
        child: SizedBox(height: AppDimens.space32),
      );
    }

    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) => prev.spots.isEmpty != curr.spots.isEmpty,
      builder: (context, state) {
        final height = state.spots.isEmpty ? 100.0 : AppDimens.space32;
        return SliverToBoxAdapter(child: SizedBox(height: height));
      },
    );
  }
}

class _BottomSaveButton extends StatelessWidget {
  const _BottomSaveButton();

  @override
  Widget build(BuildContext context) {
    if (context.isWideScreen) return const SizedBox.shrink();

    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) => prev.spots.isEmpty != curr.spots.isEmpty,
      builder: (context, state) {
        if (state.spots.isNotEmpty) return const SizedBox.shrink();

        return PrimaryBottomButton(
          label: context.l10n.saveThisSpot,
          icon: const Icon(Icons.add_rounded),
          onPressed: () {
            AdaptiveNavigation.openSaveSpot(context);
          },
        );
      },
    );
  }
}

class _SavedSpotsSectionHeader extends StatelessWidget {
  const _SavedSpotsSectionHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) =>
          prev.spots.length != curr.spots.length || prev.car != curr.car,
      builder: (context, state) {
        if (state.spots.isEmpty && state.car == null) {
          return const SizedBox.shrink();
        }

        return SectionHeader(
          title: context.l10n.savedSpots,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ExportSpotsButton(spots: state.allSpots),
              const SizedBox(width: AppDimens.space8),
              CircleIconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: context.l10n.searchSpots,
                onPressed: () {
                  AdaptiveNavigation.openSearch(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExportSpotsButton extends StatelessWidget {
  const _ExportSpotsButton({required this.spots});

  final List<Spot> spots;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      icon: const Icon(Icons.share),
      tooltip: context.l10n.exportData,
      onPressed: () {
        final box = context.findRenderObject() as RenderBox?;
        final origin = (box != null && box.hasSize)
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: false,
          builder: (_) =>
              ExportSpotsSheet(spots: spots, sharePositionOrigin: origin),
        );
      },
    );
  }
}

class _SavedSpotsSliverList extends StatelessWidget {
  const _SavedSpotsSliverList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) =>
          prev.spots != curr.spots ||
          prev.favoriteSpotId != curr.favoriteSpotId,
      builder: (context, state) {
        if (state.spots.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(
              lottieAsset: AppAssets.locationLottie,
              title: context.l10n.emptySpotsTitle,
              message: context.l10n.emptySpotsMessage,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final spot = state.spots[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppDimens.space12,
                ),
                child: _DismissibleSpotItem(
                  spot: spot,
                  isFavorite: spot.id == state.favoriteSpotId,
                ),
              );
            }, childCount: state.spots.length),
          ),
        );
      },
    );
  }
}

class _DismissibleSpotItem extends StatelessWidget {
  const _DismissibleSpotItem({required this.spot, required this.isFavorite});

  final Spot spot;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final spotsCubit = context.read<SpotsCubit>();
    final l10n = context.l10n;

    return Dismissible(
      key: ValueKey('spot_${spot.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppDimens.space20),
        decoration: BoxDecoration(
          color: context.colorScheme.error,
          borderRadius: AppDimens.borderRadiusLarge,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: AppDimens.iconLarge,
        ),
      ),
      onDismissed: (_) {
        spotsCubit.deleteSpot(spot.id);
        AppSnackBar.show(
          context,
          content: Text(l10n.spotDeleted(spot.name)),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () {
              spotsCubit.restoreSpot(spot);
            },
          ),
        );
      },
      child: SpotCard(
        spot: spot,
        isFavorite: isFavorite,
        onShowOnMap: () {
          AdaptiveNavigation.openMap(context, spotId: spot.id);
        },
        onLongPress: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: false,
            builder: (_) => RenameSpotSheet(
              spot: spot,
              isFavorite: isFavorite,
              onRename: (newName) {
                spotsCubit.renameSpot(id: spot.id, newName: newName);
              },
              onToggleFavorite: () {
                final newFav = isFavorite ? null : spot.id;
                spotsCubit.setFavoriteSpot(newFav);
              },
            ),
          );
        },
      ),
    );
  }
}
