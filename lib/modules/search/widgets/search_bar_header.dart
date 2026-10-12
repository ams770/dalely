import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../cubit/search_spots_cubit.dart';
import '../cubit/search_spots_state.dart';

class SearchBarHeader extends StatelessWidget {
  const SearchBarHeader({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchSpotsCubit>();
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space8,
      ),
      child: Row(
        children: [
          CircleIconButton(
            icon: const BackButtonIcon(),
            tooltip: context.l10n.backTooltip,
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: TextField(
              controller: cubit.textController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: context.l10n.searchSpotsPlaceholder,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: BlocSelector<SearchSpotsCubit, SearchSpotsState, bool>(
                  selector: (state) => state.query.isNotEmpty,
                  builder: (context, hasQuery) {
                    if (!hasQuery) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: context.l10n.clearSearch,
                      onPressed: cubit.clearQuery,
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
        ],
      ),
    );
  }
}
