import 'package:flutter/material.dart';

import '../constants/spot_categories.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// Selectable category chips showing icons and localized labels.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.categories = SpotCategory.selectable,
  });

  final SpotCategory? selectedCategory;
  final ValueChanged<SpotCategory> onCategorySelected;
  final List<SpotCategory> categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDimens.space16,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return _CategoryChipItem(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChipItem extends StatelessWidget {
  const _CategoryChipItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final SpotCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final catColor = context.tokens.categoryColor(category);
    final theme = context.theme;

    final bg = isSelected ? catColor : theme.colorScheme.surface;
    final fg = isSelected ? Colors.white : theme.colorScheme.onSurface;
    final border = isSelected
        ? Border.all(color: catColor, width: 1.5)
        : Border.all(color: theme.colorScheme.outline, width: 1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.borderRadiusFull,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppDimens.borderRadiusFull,
            border: border,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: catColor.withAlpha(70),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: AppDimens.iconSmall,
                color: fg,
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                _getCategoryLabel(context, category),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(BuildContext context, SpotCategory category) {
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
