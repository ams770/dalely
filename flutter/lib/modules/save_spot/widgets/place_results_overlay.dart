import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../cubit/save_spot_cubit.dart';
import '../cubit/save_spot_state.dart';

/// Overlay dropdown listing search results.
class PlaceResultsOverlay extends StatelessWidget {
  const PlaceResultsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaveSpotCubit, SaveSpotState>(
      buildWhen: (prev, curr) =>
          prev.showResults != curr.showResults ||
          prev.searchResults != curr.searchResults ||
          prev.isSearching != curr.isSearching,
      builder: (context, state) {
        if (!state.showResults || state.searchQuery.isEmpty) {
          return const SizedBox.shrink();
        }

        if (state.searchResults.isEmpty && !state.isSearching) {
          return Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDimens.space16,
            ),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppDimens.space16),
                child: Text(
                  context.l10n.noSearchResults,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        final cubit = context.read<SaveSpotCubit>();

        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
          ),
          child: Card(
            elevation: 4,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.searchResults.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = state.searchResults[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    size: AppDimens.iconMedium,
                  ),
                  title: Text(
                    result.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: result.subtitle.isNotEmpty
                      ? Text(
                          result.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () => cubit.selectPlaceResult(result),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
