import 'package:feen/shared/utils/context_ext.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/theme/app_dimens.dart';


/// Single-column, scrollable list of categories (same look as the iOS sheet).
///
/// Drop-in replacement for `CategoryChips`: same two parameters.
/// Place it inside an `Expanded` so only the list scrolls while the name field
/// and the Save button stay pinned.
class CategoryList extends StatelessWidget {
  const CategoryList({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final SpotCategory selectedCategory;
  final ValueChanged<SpotCategory> onCategorySelected;

  /// "Other" first, then the rest. The car category has its own flow, so it is not listed.
  static final List<SpotCategory> _categories = [
    SpotCategory.other,
    ...SpotCategory.values.where(
      (c) => c != SpotCategory.other && c != SpotCategory.car,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDimens.space16,
        AppDimens.space4,
        AppDimens.space16,
        AppDimens.space12,
      ),
      itemCount: _categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.space8),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _CategoryRow(
          category: category,
          isSelected: category == selectedCategory,
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final SpotCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final categoryColor = context.tokens.categoryColor(category);
    final radius = BorderRadius.circular(16);

    final background = isSelected
        ? categoryColor
        : theme.colorScheme.surfaceContainerHighest.withAlpha(110);
    final foreground = isSelected ? Colors.white : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: isSelected
              ? null
              : Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(90),
                  width: 0.8,
                ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white.withAlpha(56)
                          : categoryColor.withAlpha(41),
                    ),
                    child: Icon(
                      _iconFor(category),
                      size: 18,
                      color: isSelected ? Colors.white : categoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _labelFor(context, category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // If you already have an icon source for categories (used by CategoryChips or the
  // map pins), return it here instead of this mapping.
  IconData _iconFor(SpotCategory category) {
    switch (category) {
      case SpotCategory.car:
        return Icons.directions_car_rounded;
      case SpotCategory.market:
        return Icons.shopping_cart_rounded;
      case SpotCategory.home:
        return Icons.home_rounded;
      case SpotCategory.pharmacy:
        return Icons.local_pharmacy_rounded;
      case SpotCategory.work:
        return Icons.work_rounded;
      case SpotCategory.restaurant:
        return Icons.restaurant_rounded;
      case SpotCategory.hospital:
        return Icons.local_hospital_rounded;
      case SpotCategory.school:
        return Icons.school_rounded;
      case SpotCategory.gym:
        return Icons.fitness_center_rounded;
      case SpotCategory.mosque:
        return Icons.mosque_rounded;
      case SpotCategory.fuel:
        return Icons.local_gas_station_rounded;
      case SpotCategory.park:
        return Icons.park_rounded;
      case SpotCategory.club:
        return Icons.nightlife_rounded;
      case SpotCategory.beautyCenter:
        return Icons.spa_rounded;
      case SpotCategory.other:
        return Icons.place_rounded;
    }
  }

  String _labelFor(BuildContext context, SpotCategory category) {
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
        return l10n.categoryOther;
    }
  }
}