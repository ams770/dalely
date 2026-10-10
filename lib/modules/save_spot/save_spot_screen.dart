import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../shared/constants/spot_categories.dart';
import '../../shared/cubits/location/location_cubit.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/services/place_search_service.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/app_google_map.dart';
import '../../shared/widgets/category_chips.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/primary_bottom_button.dart';
import 'cubit/save_spot_cubit.dart';
import 'cubit/save_spot_state.dart';
import 'widgets/center_pin.dart';
import 'widgets/place_results_overlay.dart';
import 'widgets/place_search_field.dart';

class SaveSpotScreen extends StatelessWidget {
  const SaveSpotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spotsCubit = context.read<SpotsCubit>();
    final locationCubit = context.read<LocationCubit>();

    return BlocProvider<SaveSpotCubit>(
      create: (_) => SaveSpotCubit(
        spotsCubit: spotsCubit,
        locationCubit: locationCubit,
        placeSearchService: PlaceSearchService(),
      ),
      child: const _SaveSpotView(),
    );
  }
}

class _SaveSpotView extends StatelessWidget {
  const _SaveSpotView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SaveSpotCubit>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Fullscreen Google Map Picker
          AppGoogleMap(
            initialCameraPosition: CameraPosition(
              target: cubit.state.target,
              zoom: 16,
            ),
            onMapCreated: cubit.onMapCreated,
            onCameraMoveStarted: cubit.onCameraMoveStarted,
            onCameraMove: cubit.onCameraMove,
            onCameraIdle: cubit.onCameraIdle,
            onTap: (_) {
              FocusScope.of(context).unfocus();
              cubit.hideSearchResults();
            },
            padding: const EdgeInsets.only(top: 100, bottom: 280),
          ),

          // Center Pin
          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: CenterPin(),
            ),
          ),

          // Top Search Bar
          const PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: PlaceSearchField(),
            ),
          ),

          // Search Dropdown Overlay
          const PositionedDirectional(
            top: 100,
            start: 0,
            end: 0,
            child: SafeArea(
              child: PlaceResultsOverlay(),
            ),
          ),

          // Snap to Current Location Button
          PositionedDirectional(
            bottom: 300,
            end: AppDimens.space16,
            child: CircleIconButton(
              icon: Icon(
                Icons.my_location_rounded,
                color: context.colorScheme.primary,
              ),
              tooltip: context.l10n.myLocation,
              onPressed: cubit.snapToCurrentLocation,
            ),
          ),

          // Bottom Details & Save Panel
          const PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: _SaveDetailsBottomPanel(),
          ),
        ],
      ),
    );
  }
}

class _SaveDetailsBottomPanel extends StatelessWidget {
  const _SaveDetailsBottomPanel();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SaveSpotCubit>();
    final theme = context.theme;
    final l10n = context.l10n;

    return Material(
      color: theme.colorScheme.surface,
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
            AppDimens.space16,
            0,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimens.space16,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.saveThisSpot,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space12),

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
              BlocSelector<SaveSpotCubit, SaveSpotState, SpotCategory>(
                selector: (state) => state.category,
                builder: (context, selectedCategory) {
                  return CategoryChips(
                    selectedCategory: selectedCategory,
                    onCategorySelected: (cat) {
                      cubit.setCategory(cat);
                      // If name is empty or default, suggest category name
                      if (cubit.nameController.text.trim().isEmpty &&
                          cat != SpotCategory.other) {
                        cubit.nameController.text = _categoryDefaultName(context, cat);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: AppDimens.space8),

              // Save Button
              BlocBuilder<SaveSpotCubit, SaveSpotState>(
                buildWhen: (prev, curr) =>
                    prev.canSave != curr.canSave || prev.status != curr.status,
                builder: (context, state) {
                  return PrimaryBottomButton(
                    label: l10n.saveHere,
                    isLoading: state.status == SaveSpotStatus.saving,
                    onPressed: state.canSave
                        ? () async {
                            final success = await cubit.saveSpot();
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.spotSaved(cubit.nameController.text.trim()),
                                  ),
                                ),
                              );
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
