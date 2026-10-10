import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_router.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/cubits/spots/spots_state.dart';
import '../../shared/models/spot.dart';
import '../../shared/services/share_service.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/car_proximity_listener.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/location_permission_banner.dart';
import '../../shared/widgets/primary_bottom_button.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/spot_card.dart';
import 'widgets/car_card.dart';
import 'widgets/home_header.dart';
import 'widgets/rename_spot_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CarProximityListener(
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
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.saveSpot);
              },
            ),
          ],
        ),
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
          actionLabel: context.l10n.shareAll,
          actionIcon: Icon(
            Icons.ios_share_rounded,
            size: AppDimens.iconSmall,
            color: context.colorScheme.primary,
          ),
          onAction: () {
            const ShareService().shareAllSpots(
              state.allSpots,
              l10n: context.l10n,
            );
          },
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
          Navigator.of(context)
              .pushNamed(AppRouter.spotsMap, arguments: spot.id);
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite
                          ? l10n.favoriteRemoved
                          : l10n.favoriteSet(spot.name),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
