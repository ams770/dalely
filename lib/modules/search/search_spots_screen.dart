import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_router.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/category_chips.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/spot_card.dart';
import 'cubit/search_spots_cubit.dart';
import 'cubit/search_spots_state.dart';
import 'widgets/search_bar_header.dart';

class SearchSpotsScreen extends StatelessWidget {
  const SearchSpotsScreen({
    super.key,
    this.onSpotSelected,
    this.onClose,
  });

  final ValueChanged<String>? onSpotSelected;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchSpotsCubit>(
      create: (context) => SearchSpotsCubit(
        spotsCubit: context.read<SpotsCubit>(),
      ),
      child: _SearchSpotsView(
        onSpotSelected: onSpotSelected,
        onClose: onClose,
      ),
    );
  }
}

class _SearchSpotsView extends StatelessWidget {
  const _SearchSpotsView({
    this.onSpotSelected,
    this.onClose,
  });

  final ValueChanged<String>? onSpotSelected;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SearchBarHeader(onBack: onClose),
            const _CategoryFilterRow(),
            Expanded(
              child: _SearchResultsList(
                onSpotSelected: onSpotSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppDimens.space4,
        bottom: AppDimens.space8,
      ),
      child: BlocSelector<SearchSpotsCubit, SearchSpotsState, dynamic>(
        selector: (state) => state.selectedCategory,
        builder: (context, selectedCategory) {
          return CategoryChips(
            selectedCategory: selectedCategory,
            onCategorySelected: (category) {
              context.read<SearchSpotsCubit>().toggleCategory(category);
            },
          );
        },
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({this.onSpotSelected});

  final ValueChanged<String>? onSpotSelected;

  @override
  Widget build(BuildContext context) {
    final spotsState = context.watch<SpotsCubit>().state;

    return BlocBuilder<SearchSpotsCubit, SearchSpotsState>(
      buildWhen: (prev, curr) => prev.matchingSpots != curr.matchingSpots,
      builder: (context, state) {
        if (state.matchingSpots.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: context.l10n.noSpotsFound,
            message: context.l10n.noSpotsFoundDesc,
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDimens.space16,
            AppDimens.space8,
            AppDimens.space16,
            AppDimens.space32,
          ),
          itemCount: state.matchingSpots.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space12),
          itemBuilder: (context, index) {
            final spot = state.matchingSpots[index];
            final isFavorite = spot.id == spotsState.favoriteSpotId;

            return SpotCard(
              spot: spot,
              isFavorite: isFavorite,
              onShowOnMap: () {
                if (onSpotSelected != null) {
                  onSpotSelected!(spot.id);
                } else {
                  Navigator.of(context).pushNamed(
                    AppRouter.spotsMap,
                    arguments: spot.id,
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
