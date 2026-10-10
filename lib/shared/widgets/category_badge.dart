import 'package:flutter/material.dart';

import '../constants/spot_categories.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// A rounded-square icon badge displaying a category's icon with its theme color.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.category,
    this.size = AppDimens.categoryBadgeSize,
    this.iconSize,
  });

  final SpotCategory category;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.categoryColor(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppDimens.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        category.icon,
        size: iconSize ?? (size * 0.52),
        color: Colors.white,
      ),
    );
  }
}
