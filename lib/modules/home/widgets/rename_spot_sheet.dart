import 'package:flutter/material.dart';

import '../../../shared/models/spot.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/category_badge.dart';

/// Bottom sheet allowing the user to rename a saved spot,
/// toggle its home-screen widget status, or save edits.
class RenameSpotSheet extends StatelessWidget {
  RenameSpotSheet({
    super.key,
    required this.spot,
    required this.isFavorite,
    required this.onRename,
    required this.onToggleFavorite,
  }) : _controller = TextEditingController(text: spot.name);

  final Spot spot;
  final bool isFavorite;
  final ValueChanged<String> onRename;
  final VoidCallback onToggleFavorite;
  final TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimens.space20,
        AppDimens.space12,
        AppDimens.space20,
        MediaQuery.viewInsetsOf(context).bottom + AppDimens.space20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withAlpha(160),
                borderRadius: AppDimens.borderRadiusFull,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // Header with category badge and title
          Row(
            children: [
              CategoryBadge(category: spot.category),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  l10n.renameSpotTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.cancel,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),

          // Name TextField
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              hintText: l10n.nameHint,
            ),
            onSubmitted: (_) => _handleSave(context),
          ),
          const SizedBox(height: AppDimens.space12),

          // Widget favorite toggle button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onToggleFavorite();
            },
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFavorite
                  ? context.tokens.categoryColor(spot.category)
                  : null,
            ),
            label: Text(
              isFavorite ? l10n.removeFromWidget : l10n.showOnWidget,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              shape: const RoundedRectangleBorder(
                borderRadius: AppDimens.borderRadiusMedium,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space12),

          // Primary Save button
          FilledButton(
            onPressed: () => _handleSave(context),
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size(double.infinity, AppDimens.primaryButtonHeight),
              shape: const RoundedRectangleBorder(
                borderRadius: AppDimens.borderRadiusMedium,
              ),
            ),
            child: Text(
              l10n.save,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isNotEmpty && text != spot.name) {
      onRename(text);
    }
    Navigator.of(context).pop();
  }
}
