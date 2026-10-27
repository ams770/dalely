import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_router.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/adaptive_layout_ext.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/adaptive_expand_listener.dart';
import '../../shared/widgets/category_chips.dart';
import '../../shared/widgets/circle_icon_button.dart';
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
    this.initialQuery,
  });

  final ValueChanged<String>? onSpotSelected;
  final VoidCallback? onClose;
  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchSpotsCubit>(
      create: (context) => SearchSpotsCubit(
        spotsCubit: context.read<SpotsCubit>(),
        initialQuery: initialQuery,
      ),
      child: _SearchSpotsView(onSpotSelected: onSpotSelected, onClose: onClose),
    );
  }
}

class _SearchSpotsView extends StatelessWidget {
  const _SearchSpotsView({this.onSpotSelected, this.onClose});

  final ValueChanged<String>? onSpotSelected;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AdaptiveExpandListener(
      enabled: onClose == null,
      onExpandToTwoPane: () {
        AdaptiveNavCubit? navCubit;
        try {
          navCubit = context.read<AdaptiveNavCubit>();
        } catch (_) {}
        if (navCubit != null) {
          final query = context.read<SearchSpotsCubit>().state.query;
          navCubit.openSearch(
            query: query.isNotEmpty ? query : null,
          );
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          right: (context.isRtl && !context.isWideScreen) || !context.isRtl,
          left: (!context.isRtl && !context.isWideScreen) || context.isRtl,

          child: Column(
            children: [
              SearchBarHeader(onBack: onClose),

              const _CategoryFilterRow(),
              Expanded(child: _SearchResultsList(onSpotSelected: onSpotSelected)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchSpotsCubit, SearchSpotsState>(
      buildWhen: (prev, curr) =>
          prev.availableCategories != curr.availableCategories ||
          prev.selectedCategory != curr.selectedCategory,
      builder: (context, state) {
        if (state.availableCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        final cubit = context.read<SearchSpotsCubit>();
        final theme = context.theme;

        return Padding(
          padding: const EdgeInsetsDirectional.only(
            top: AppDimens.space4,
            bottom: AppDimens.space8,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16,
                      ),
                      child: TextField(
                        controller: cubit.textController,
                        autofocus: true,
                        textInputAction: .search,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchSpotsPlaceholder,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon:
                              BlocSelector<
                                SearchSpotsCubit,
                                SearchSpotsState,
                                bool
                              >(
                                selector: (state) => state.query.isNotEmpty,
                                builder: (context, hasQuery) {
                                  if (!hasQuery) return const SizedBox.shrink();
                                  return CircleIconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    tooltip: context.l10n.clearSearch,
                                    onPressed: cubit.clearQuery,
                                    size: 36,
                                    iconSize: 18,
                                  );
                                },
                              ),
                          contentPadding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppDimens.space16,
                            vertical: AppDimens.space12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppDimens.space12),

              CategoryChips(
                categories: state.availableCategories,
                selectedCategory: state.selectedCategory,
                onCategorySelected: (category) {
                  context.read<SearchSpotsCubit>().toggleCategory(category);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({this.onSpotSelected});

  final ValueChanged<String>? onSpotSelected;

  @override
  Widget build(BuildContext context) {
    final spotsState = context.watch<SpotsCubit>().state;
    final cubit = context.read<SearchSpotsCubit>();

    return BlocBuilder<SearchSpotsCubit, SearchSpotsState>(
      buildWhen: (prev, curr) =>
          prev.matchingSpots != curr.matchingSpots ||
          prev.visibleCount != curr.visibleCount,
      builder: (context, state) {
        if (state.matchingSpots.isEmpty) {
          return EmptyState(
            icon: Icons.search_off_rounded,
            title: context.l10n.noSpotsFound,
            message: context.l10n.noSpotsFoundDesc,
          );
        }

        final displayedSpots = state.matchingSpots
            .take(state.visibleCount)
            .toList();

        return ListView.separated(
          controller: cubit.scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDimens.space16,
            AppDimens.space8,
            AppDimens.space16,
            AppDimens.space32,
          ),
          itemCount: displayedSpots.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space12),
          itemBuilder: (context, index) {
            final spot = displayedSpots[index];
            final isFavorite = spot.id == spotsState.favoriteSpotId;

            return SpotCard(
              spot: spot,
              isFavorite: isFavorite,
              onShowOnMap: () {
                if (onSpotSelected != null) {
                  onSpotSelected!(spot.id);
                } else {
                  Navigator.of(context)
                      .pushNamed(AppRouter.spotsMap, arguments: spot.id);
                }
              },
            );
          },
        );
      },
    );
  }
}
