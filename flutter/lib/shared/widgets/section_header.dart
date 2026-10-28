import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import 'adaptive/adaptive_ui.dart';

/// Section title with an optional trailing action (e.g., "Share all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final Widget? actionIcon;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppDimens.space8),
          trailing!,
        ]
        else if (actionLabel != null && onAction != null)
          AdaptiveButton.child(
            onPressed: onAction,
            style: AdaptiveButtonStyle.plain,
            color: context.colorScheme.primary,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppDimens.space8,
              vertical: AppDimens.space4,
            ),
            minSize: const Size(0, 36),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (actionIcon != null) ...[
                  actionIcon!,
                  const SizedBox(width: AppDimens.space4),
                ],
                Text(
                  actionLabel!,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

