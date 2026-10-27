import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_router.dart';
import '../../shared/constants/app_assets.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_state.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/cubits/spots/spots_state.dart';
import '../../shared/models/spot.dart';
import '../../shared/services/maps_launcher.dart';
import '../../shared/services/share_service.dart';
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
        child: _AdaptiveCollapseListener(
          child: context.isTwoPaneLayout
              ? const _AdaptiveTwoPaneHome()
              : context.isDuoFolded
              ? const _DuoFoldedHomeLayout()
              : const _HomePane(),
        ),
      ),
    );
  }
}

class _AdaptiveCollapseListener extends StatelessWidget {
  const _AdaptiveCollapseListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isTwoPane = context.isTwoPaneLayout;
    if (!isTwoPane) {
      final navState = context.read<AdaptiveNavCubit>().state;
      if (navState.detailPane != DetailPaneType.map) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final modal = ModalRoute.of(context);
          if (modal != null && !modal.isCurrent) return;

          final cubit = context.read<AdaptiveNavCubit>();
          final currentDetail = cubit.state.detailPane;
          if (currentDetail == DetailPaneType.settings) {
            cubit.closeDetail();
            Navigator.of(context).pushNamed(AppRouter.settings);
          } else if (currentDetail == DetailPaneType.search) {
            final query = cubit.state.searchQuery;
            cubit.closeDetail();
            Navigator.of(context).pushNamed(
              AppRouter.search,
              arguments: query,
            );
          } else if (currentDetail == DetailPaneType.parkingHistory) {
            cubit.closeDetail();
            Navigator.of(context).pushNamed(AppRouter.parkingHistory);
          }
        });
      }
    }
    return child;
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
          if ((context.isFoldableDevice || context.isWideScreen) )
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
          fit: StackFit.expand,
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
                  initialQuery: state.searchQuery,
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
                      AppDimens.space16,
                      AppDimens.space16,
                      AppDimens.space16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        const LocationPermissionBanner(),
                        const _HomeCardsGrid(),
                      ]),
                    ),
                  ),
                  const _PinnedSavedSpotsHeader(),
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
                      ]),
                    ),
                  ),
                  const _PinnedSavedSpotsHeader(),
                  const _SavedSpotsSliverList(),
                  const _BottomListSpacer(),
                ],
              ),
            ),
          ),

          // Vertical action rail positioned on the outer edge (away from the center hinge)
          Positioned(
            bottom: context.height / 5,
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
          if (!context.isTwoPaneLayout) ...[
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
            !context.isTwoPaneLayout &&
            !context.isSmallScreen) {
          return SafeArea(
            child: PrimaryBottomButton(
              label: context.l10n.saveThisSpot,
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                AdaptiveNavigation.openSaveSpot(context);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _PinnedSavedSpotsHeader extends StatelessWidget {
  const _PinnedSavedSpotsHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) =>
          prev.spots.length != curr.spots.length ||
          prev.car != curr.car ||
          prev.sortOrder != curr.sortOrder,
      builder: (context, state) {
        if (state.spots.where((item) => !item.isParking).isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverPersistentHeader(
          pinned: true,
          delegate: _SavedSpotsHeaderDelegate(
            spots: state.allSpots,
          ),
        );
      },
    );
  }
}

class _SavedSpotsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SavedSpotsHeaderDelegate({required this.spots});

  final List<Spot> spots;

  static const double _headerHeight = 52.0;

  @override
  double get minExtent => _headerHeight;

  @override
  double get maxExtent => _headerHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = context.theme;
    final isPinned = shrinkOffset > 0 || overlapsContent;

    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: isPinned
            ? Border(
                bottom: BorderSide(
                  color: context.colorScheme.outlineVariant.withAlpha(
                    context.isDarkMode ? 45 : 70,
                  ),
                  width: 0.5,
                ),
              )
            : null,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space16,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: SectionHeader(
        title: context.l10n.savedSpots,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExportSpotsButton(spots: spots),
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
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SavedSpotsHeaderDelegate oldDelegate) {
    return oldDelegate.spots != spots;
  }
}

class _SortSpotsButton extends StatelessWidget {
  const _SortSpotsButton();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final isDark = context.isDarkMode;
    final currentOrder = context.select<SpotsCubit, SpotSortOrder>(
      (c) => c.state.sortOrder,
    );

    final surfaceColor = isDark
        ? const Color(0xF21E293B)
        : const Color(0xF8FFFFFF);
    final borderColor = isDark
        ? Colors.white.withAlpha(25)
        : Colors.black.withAlpha(15);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    );

    return PopupMenuButton<SpotSortOrder>(
      tooltip: l10n.sortBy,
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: Colors.black.withAlpha(isDark ? 80 : 35),
      surfaceTintColor: Colors.transparent,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimens.borderRadiusMedium,
        side: BorderSide(color: borderColor, width: 0.5),
      ),
      onSelected: (order) {
        context.read<SpotsCubit>().setSortOrder(order);
      },
      itemBuilder: (context) => [
        _buildItem(
          context: context,
          value: SpotSortOrder.dateDesc,
          label: l10n.sortByDateDesc,
          isSelected: currentOrder == SpotSortOrder.dateDesc,
          textStyle: textStyle,
        ),
        _buildItem(
          context: context,
          value: SpotSortOrder.nearest,
          label: l10n.sortByNearest,
          isSelected: currentOrder == SpotSortOrder.nearest,
          textStyle: textStyle,
        ),
        _buildItem(
          context: context,
          value: SpotSortOrder.category,
          label: l10n.sortByCategory,
          isSelected: currentOrder == SpotSortOrder.category,
          textStyle: textStyle,
        ),
        _buildItem(
          context: context,
          value: SpotSortOrder.name,
          label: l10n.sortByName,
          isSelected: currentOrder == SpotSortOrder.name,
          textStyle: textStyle,
        ),
      ],
      child: CircleIconButton(
        icon: const Icon(Icons.sort_rounded),
        tooltip: l10n.sortBy,
        onPressed: null,
      ),
    );
  }

  PopupMenuItem<SpotSortOrder> _buildItem({
    required BuildContext context,
    required SpotSortOrder value,
    required String label,
    required bool isSelected,
    required TextStyle? textStyle,
  }) {
    return PopupMenuItem<SpotSortOrder>(
      value: value,
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: context.colorScheme.primary,
                  )
                : null,
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            label,
            style: textStyle?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDimens.space16,
            AppDimens.space12,
            AppDimens.space16,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final spot = displayedSpots[index];
                return Padding(
                  key: ValueKey(spot.id),
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppDimens.space12,
                  ),
                  child: _DismissibleSpotItem(
                    spot: spot,
                    isFavorite: spot.id == state.favoriteSpotId,
                  ),
                );
              },
              childCount: displayedSpots.length,
              findChildIndexCallback: (Key key) {
                if (key is ValueKey<String>) {
                  final idx =
                      displayedSpots.indexWhere((s) => s.id == key.value);
                  return idx >= 0 ? idx : null;
                }
                return null;
              },
            ),
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

    void handleShowOnMap() {
      AdaptiveNavigation.openMap(context, spotId: spot.id);
    }

    void handleOpenInMaps() {
      const MapsLauncher().openDirections(
        latitude: spot.latitude,
        longitude: spot.longitude,
        label: spot.name,
      );
    }

    void handleShare() {
      const ShareService().shareSpot(spot, l10n: l10n);
    }

    void handleEdit() {
      AdaptiveNavigation.openEditSpot(context, spot);
    }

    void handleDelete() {
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
    }

    return SpotCard(
      spot: spot,
      isFavorite: isFavorite,
      onShowOnMap: handleShowOnMap,
      onOpenInMaps: handleOpenInMaps,
      onShare: handleShare,
      onEdit: handleEdit,
      onDelete: handleDelete,
    );
  }
}
