import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// A docked or floating search pill in the thumb zone matching Apple's native design.
class BottomSearchPill extends StatelessWidget {
  const BottomSearchPill({
    super.key,
    this.placeholder,
    required this.onTap,
  });

  final String? placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: AppDimens.borderRadiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimens.borderRadiusMedium,
        child: InkWell(
          onTap: () {
            Feedback.forTap(context);
            onTap();
          },
          borderRadius: AppDimens.borderRadiusMedium,
          hoverColor: textSecondary.withAlpha(isDark ? 35 : 20),
          highlightColor: textSecondary.withAlpha(isDark ? 60 : 40),
          splashColor: textSecondary.withAlpha(isDark ? 80 : 60),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDimens.space16,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20.0,
                  color: textSecondary,
                ),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text(
                    placeholder ?? context.l10n.searchSpots,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.mic_rounded,
                  size: 18.0,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
