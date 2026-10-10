import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../cubit/save_spot_cubit.dart';
import '../cubit/save_spot_state.dart';

/// Search input bar shown at the top of the Save Spot picker.
class PlaceSearchField extends StatelessWidget {
  const PlaceSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SaveSpotCubit>();
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space8,
      ),
      child: Row(
        children: [
          CircleIconButton(
            icon: const BackButtonIcon(),
            tooltip: context.l10n.backTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: AppDimens.borderRadiusLarge,
              elevation: 2,
              shadowColor: Colors.black.withAlpha(20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: AppDimens.borderRadiusLarge,
                  border: Border.all(
                    color: theme.colorScheme.outline.withAlpha(120),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: AppDimens.iconMedium,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Expanded(
                      child: TextField(
                        controller: cubit.searchController,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchPlaceHint,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                    BlocBuilder<SaveSpotCubit, SaveSpotState>(
                      buildWhen: (prev, curr) =>
                          prev.searchQuery != curr.searchQuery ||
                          prev.isSearching != curr.isSearching,
                      builder: (context, state) {
                        if (state.isSearching) {
                          return const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        if (state.searchQuery.isNotEmpty) {
                          return IconButton(
                            icon: const Icon(Icons.close_rounded),
                            iconSize: AppDimens.iconSmall,
                            tooltip: context.l10n.clearSearch,
                            onPressed: cubit.clearSearch,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
