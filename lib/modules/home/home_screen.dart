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
import '../../shared/widgets/duo_action_rail.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/location_permission_banner.dart';
import '../../shared/widgets/primary_bottom_button.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/spot_card.dart';
import '../parking_history/parking_history_screen.dart';
import '../search/search_spots_screen.dart';
import '../settings/settings_screen.dart';
import '../spots_map/spots_map_screen.dart';
import 'cubit/home_cubit.dart';
import 'widgets/car_card.dart';
import 'widgets/export_spots_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/home_map_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (context) => HomeCubit(spotsCubit: context.read<SpotsCubit>()),
      child: CarProximityListener(
        child: context.isSplitLayout
            ? const _AdaptiveTwoPaneHome()
            : context.isDuoFolded
            ? const _DuoFoldedHomeLayout()
            : const _HomePane(),
      ),
    );
  }
}

class _AdaptiveTwoPaneHome extends StatelessWidget {
  const _AdaptiveTwoPaneHome();

  @override
  Widget build(BuildContext context) {
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
          if (context.isFoldableDevice || context.isWideScreen)
            Expanded(flex: context.isRtl ? 9 : 8, child: _HomePane())
          else
            const SizedBox(width: 440.0, child: _HomePane()),

          // Professional Adaptive Pane Separator
          const _AdaptivePaneSeparator(),

          // Right Pane: Active Detail (Map by default, or Settings, SaveSpot, Search)
          // On tablets, takes all remaining space (the largest area).
          // On foldable/flip devices, takes the second half (50%).
          Expanded(flex: !context.isRtl ? 9 : 8, child: _AdaptiveDetailPane()),
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
              )
            // Parking history overlay
            else if (state.detailPane == DetailPaneType.parkingHistory)
              Positioned.fill(
                child: ParkingHistoryScreen(onClose: cubit.closeDetail),
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
    final homeCubit = context.read<HomeCubit>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        left: false,
        right: context.isRtl,
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: CustomScrollView(
                controller: homeCubit.scrollController,
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
            const _BottomActionArea(),
          ],
        ),
      ),
    );
  }
}

class _DuoFoldedHomeLayout extends StatelessWidget {
  const _DuoFoldedHomeLayout();

  @override
  Widget build(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final isLeft = context.isDuoLeftScreen;

    return Scaffold(
      body: Stack(
        children: [
          // Main content column padded away from the vertical action rail.
          // Physical constraint: On a dual-screen device, if opened on the left screen,
          // the outer bezel/thumb edge is on the physical left and the hinge is on the right.
          // If opened on the right screen, the outer bezel is on the physical right.
          SafeArea(
            bottom: false,
            left: false,
            right: false,
            child: Padding(
              padding: isLeft
                  ? const EdgeInsets.only(left: 78.0)
                  : const EdgeInsets.only(right: 78.0),
              child: CustomScrollView(
                controller: homeCubit.scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppDimens.space16,
                      AppDimens.space16,
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
          ),

          // Vertical action rail positioned on the outer edge (away from the center hinge)
          Positioned(
            top: 168.0,
            left: isLeft ? 22.0 : null,
            right: isLeft ? null : 22.0,
            child: DuoActionRail(
              onSettings: () {
                AdaptiveNavigation.openSettings(context);
              },
              onHistory: () {
                AdaptiveNavigation.openParkingHistory(context);
              },
              onMap: () {
                AdaptiveNavigation.openMap(context);
              },
              onAddSpot: () {
                AdaptiveNavigation.openSaveSpot(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCardsGrid extends StatelessWidget {
  const _HomeCardsGrid();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: CarCard()),
          if (!context.isSplitLayout) ...[
            SizedBox(width: AppDimens.space12),
            Expanded(child: HomeMapCard()),
          ],
        ],
      ),
    );
  }
}

class _BottomListSpacer extends StatelessWidget {
  const _BottomListSpacer();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(child: SizedBox(height: AppDimens.space20));
  }
}

class _BottomActionArea extends StatelessWidget {
  const _BottomActionArea();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) => prev.spots.isEmpty != curr.spots.isEmpty,
      builder: (context, state) {
        if (state.spots.isEmpty &&
            !context.isSplitLayout &&
            !context.isSmallScreen) {
          return PrimaryBottomButton(
            label: context.l10n.saveThisSpot,
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              AdaptiveNavigation.openSaveSpot(context);
            },
          );
        }

        return const SizedBox.shrink();
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
        if (state.spots.where((item) => !item.isParking).isEmpty) {
          return const SizedBox.shrink();
        }

        return SectionHeader(
          title: context.l10n.savedSpots,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ExportSpotsButton(spots: state.allSpots),
              const SizedBox(width: AppDimens.space8),
              const _SortSpotsButton(),
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

class _SortSpotsButton extends StatelessWidget {
  const _SortSpotsButton();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentOrder = context.select<SpotsCubit, SpotSortOrder>(
      (c) => c.state.sortOrder,
    );

    return CircleIconButton(
      icon: const Icon(Icons.sort_rounded),
      tooltip: l10n.sortBy,
      onPressed: () async {
        final box = context.findRenderObject() as RenderBox?;
        final origin = (box != null && box.hasSize)
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.zero;

        final selected = await showMenu<SpotSortOrder>(
          context: context,
          position: RelativeRect.fromLTRB(
            origin.left,
            origin.bottom + 8,
            origin.right,
            origin.bottom + 8,
          ),
          items: [
            PopupMenuItem(
              value: SpotSortOrder.dateDesc,
              child: _SortMenuItem(
                label: l10n.sortByDateDesc,
                isSelected: currentOrder == SpotSortOrder.dateDesc,
              ),
            ),
            PopupMenuItem(
              value: SpotSortOrder.nearest,
              child: _SortMenuItem(
                label: l10n.sortByNearest,
                isSelected: currentOrder == SpotSortOrder.nearest,
              ),
            ),
            PopupMenuItem(
              value: SpotSortOrder.category,
              child: _SortMenuItem(
                label: l10n.sortByCategory,
                isSelected: currentOrder == SpotSortOrder.category,
              ),
            ),
            PopupMenuItem(
              value: SpotSortOrder.name,
              child: _SortMenuItem(
                label: l10n.sortByName,
                isSelected: currentOrder == SpotSortOrder.name,
              ),
            ),
          ],
        );

        if (selected != null && context.mounted) {
          context.read<SpotsCubit>().setSortOrder(selected);
        }
      },
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  const _SortMenuItem({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check_rounded,
            size: AppDimens.iconMedium,
            color: theme.colorScheme.primary,
          ),
      ],
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
    final visibleCount = context.select<HomeCubit, int>(
      (c) => c.state.visibleCount,
    );

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

        final displayedSpots = state.spots.take(visibleCount).toList();

        return SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final spot = displayedSpots[index];
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppDimens.space12,
                ),
                child: _DismissibleSpotItem(
                  spot: spot,
                  isFavorite: spot.id == state.favoriteSpotId,
                ),
              );
            }, childCount: displayedSpots.length),
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
          AdaptiveNavigation.openEditSpot(context, spot);
        },
      ),
    );
  }
}
