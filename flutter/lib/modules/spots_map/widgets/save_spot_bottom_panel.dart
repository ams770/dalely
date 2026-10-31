import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/spot.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../../../shared/widgets/primary_bottom_button.dart';
import '../cubit/spots_map_cubit.dart';
import '../cubit/spots_map_state.dart';
import 'category_list.dart';

/// Content of the details sheet (name, category, save), same layout as the iOS sheet:
/// pinned header, pinned name field, one scrollable column of categories,
/// pinned Save button.
///
/// It is shown with `showModalBottomSheet` after the user taps "Pick here" and expects
/// a bounded height (the screen gives it a fixed fraction of the screen height).
/// [onClose] only closes the sheet and returns the user to picking.
class SaveSpotBottomPanel extends StatelessWidget {
  const SaveSpotBottomPanel({super.key, required this.onSaved, this.onClose});

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet Drag Handle Pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: AppDimens.borderRadiusFull,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space8),

              // Header Row with Title & Cancel Button (pinned)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppDimens.space16,
                  end: AppDimens.space8,
                  bottom: AppDimens.space4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BlocSelector<SpotsMapCubit, SpotsMapState, bool>(
                      selector: (state) => state.isEditingSpot,
                      builder: (context, isEditing) {
                        return Text(
                          isEditing ? l10n.editSpot : l10n.saveThisSpot,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    CircleIconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.cancel,
                      onPressed: onClose ?? cubit.closeDetailsSheet,
                      size: 36,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space8),

              // Spot Name Input (pinned)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space16,
                ),
                child: TextField(
                  controller: cubit.nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    hintText: l10n.nameHint,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              // Categories: one column, only this part scrolls
              Expanded(
                child: BlocSelector<SpotsMapCubit, SpotsMapState, SpotCategory>(
                  selector: (state) => state.category,
                  builder: (context, selectedCategory) {
                    return CategoryList(
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
              ),

              // Save Button (pinned)
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

              // // Privacy Footnote
              // Padding(
              //   padding: const EdgeInsetsDirectional.only(
              //     bottom: AppDimens.space8,
              //   ),
              //   child: Text(
              //     l10n.savedLocallyNote,
              //     textAlign: TextAlign.center,
              //     style: theme.textTheme.bodySmall?.copyWith(
              //       color: theme.colorScheme.onSurfaceVariant,
              //     ),
              //   ),
              // ),
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
      case SpotCategory.park:
        return l10n.categoryPark;
      case SpotCategory.club:
        return l10n.categoryClub;
      case SpotCategory.beautyCenter:
        return l10n.categoryBeautyCenter;
      case SpotCategory.other:
        return '';
    }
  }
}
