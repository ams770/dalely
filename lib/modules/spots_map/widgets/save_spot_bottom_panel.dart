import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/category_chips.dart';
import '../../../shared/widgets/primary_bottom_button.dart';
import '../cubit/spots_map_cubit.dart';
import '../cubit/spots_map_state.dart';

class SaveSpotBottomPanel extends StatelessWidget {
  const SaveSpotBottomPanel({
    super.key,
    required this.onSaved,
    this.onClose,
  });

  final ValueChanged<Spot> onSaved;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SpotsMapCubit>();
    final theme = context.theme;
    final l10n = context.l10n;

    return Material(
      color:
          theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surface,
      borderRadius: const BorderRadiusDirectional.vertical(
        top: Radius.circular(AppDimens.radiusLarge),
      ),
      elevation: 12,
      shadowColor: Colors.black.withAlpha(80),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            0,
            AppDimens.space12,
            0,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row with Title & Cancel Button
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppDimens.space16,
                  end: AppDimens.space8,
                  bottom: AppDimens.space4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.saveThisSpot,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.cancel,
                      onPressed: onClose ?? cubit.exitAddSpotMode,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space8),

              // Spot Name Input
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space16,
                ),
                child: TextField(
                  controller: cubit.nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    hintText: l10n.nameHint,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              // Category Selector Chips
              BlocSelector<SpotsMapCubit, SpotsMapState, SpotCategory>(
                selector: (state) => state.category,
                builder: (context, selectedCategory) {
                  return CategoryChips(
                    selectedCategory: selectedCategory,
                    onCategorySelected: (cat) {
                      cubit.setCategory(cat);
                      if (cubit.nameController.text.trim().isEmpty &&
                          cat != SpotCategory.other) {
                        cubit.nameController.text = _categoryDefaultName(
                          context,
                          cat,
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: AppDimens.space8),

              // Save Button
              BlocBuilder<SpotsMapCubit, SpotsMapState>(
                buildWhen: (prev, curr) =>
                    prev.canSave != curr.canSave ||
                    prev.isSaving != curr.isSaving,
                builder: (context, state) {
                  return PrimaryBottomButton(
                    label: l10n.saveHere,
                    isLoading: state.isSaving,
                    onPressed: state.canSave
                        ? () async {
                            final spot = await cubit.saveCurrentSpot();
                            if (spot != null && context.mounted) {
                              onSaved(spot);
                            }
                          }
                        : null,
                  );
                },
              ),

              // Privacy Footnote
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppDimens.space8,
                ),
                child: Text(
                  l10n.savedLocallyNote,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryDefaultName(BuildContext context, SpotCategory category) {
    final l10n = context.l10n;
    switch (category) {
      case SpotCategory.car:
        return l10n.categoryCar;
      case SpotCategory.market:
        return l10n.categoryMarket;
      case SpotCategory.home:
        return l10n.categoryHome;
      case SpotCategory.pharmacy:
        return l10n.categoryPharmacy;
      case SpotCategory.work:
        return l10n.categoryWork;
      case SpotCategory.restaurant:
        return l10n.categoryRestaurant;
      case SpotCategory.hospital:
        return l10n.categoryHospital;
      case SpotCategory.school:
        return l10n.categorySchool;
      case SpotCategory.gym:
        return l10n.categoryGym;
      case SpotCategory.mosque:
        return l10n.categoryMosque;
      case SpotCategory.fuel:
        return l10n.categoryFuel;
      case SpotCategory.other:
        return '';
    }
  }
}
