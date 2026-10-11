import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_state.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/cubits/spots/spots_state.dart';
import '../../shared/models/spot.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/adaptive_layout_ext.dart';
import '../../shared/utils/adaptive_navigation.dart';
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
import 'widgets/home_header.dart';
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
    final theme = context.theme;

    return Scaffold(
      body: Row(
        children: [
          // Left Pane: Home (portrait column)
          const SizedBox(
            width: 390.0,
            child: _HomePane(),
          ),

          // Pane Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),

          // Right Pane: Active Detail (Map by default, or Settings, SaveSpot, Search)
          const Expanded(
            child: _AdaptiveDetailPane(),
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
              Positioned.fill(
                child: SettingsScreen(
                  onClose: cubit.closeDetail,
                ),
              )
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
    return Scaffold(
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
                        const CarCard(),
                        const SizedBox(height: AppDimens.space24),
                        const _SavedSpotsSectionHeader(),
                      ]),
                    ),
                  ),
                  const _SavedSpotsSliverList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            PrimaryBottomButton(
              label: context.l10n.saveThisSpot,
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                AdaptiveNavigation.openSaveSpot(context);
              },
            ),
          ],
        ),
      ),
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
          trailing: CircleIconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: context.l10n.searchSpots,
            onPressed: () {
              AdaptiveNavigation.openSearch(context);
            },
          ),
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
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text(l10n.spotDeleted(spot.name)),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () {
                spotsCubit.restoreSpot(spot);
              },
            ),
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
