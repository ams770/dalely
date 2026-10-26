import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';
import 'circle_icon_button.dart';

/// Vertical action rail for compact dual-screen (iPhone Duo) devices.
/// Sits in the trailing thumb rail directly beneath the hardware status clock.
class DuoActionRail extends StatelessWidget {
  const DuoActionRail({
    super.key,
    required this.onSettings,
    required this.onHistory,
    required this.onMap,
    required this.onAddSpot,
  });

  final VoidCallback onSettings;
  final VoidCallback onHistory;
  final VoidCallback onMap;
  final VoidCallback onAddSpot;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: 52.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimens.space12),
          // 1. Settings Action
          CircleIconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: l10n.settingsTooltip,
            onPressed: onSettings,
            size: 44.0,
            iconSize: 20.0,
          ),

          const SizedBox(height: AppDimens.space16),
          // 2. Primary Add Action
          CircleIconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.addSpot,
            onPressed: onAddSpot,
            size: 46.0,
            iconSize: 24.0,
            backgroundColor: AppColors.lightPrimary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
