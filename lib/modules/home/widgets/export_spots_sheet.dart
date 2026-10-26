import 'package:flutter/material.dart';

import '../../../shared/models/spot.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';

/// Bottom sheet allowing users to export saved spots as an Excel spreadsheet (CSV)
/// or formatted text list.
class ExportSpotsSheet extends StatelessWidget {
  const ExportSpotsSheet({
    super.key,
    required this.spots,
    this.sharePositionOrigin,
  });

  final List<Spot> spots;
  final Rect? sharePositionOrigin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDimens.space20,
        AppDimens.space12,
        AppDimens.space20,
        AppDimens.space20,
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

          // Sheet title and close action
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.file_upload_outlined,
                  color: theme.colorScheme.primary,
                  size: AppDimens.iconMedium,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  l10n.exportSpotsTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CircleIconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.cancel,
                size: 36,
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space20),

          // Export as Excel (CSV)
          _ExportOptionCard(
            icon: Icons.table_chart_rounded,
            title: l10n.exportAsExcel,
            subtitle: l10n.exportAsExcelSubtitle,
            onTap: () {
              Navigator.of(context).pop();
              const ShareService().shareAllSpotsAsCsv(
                spots,
                l10n: l10n,
                sharePositionOrigin: sharePositionOrigin,
              );
            },
          ),
          const SizedBox(height: AppDimens.space12),

          // Export as Text
          _ExportOptionCard(
            icon: Icons.text_snippet_rounded,
            title: l10n.exportAsText,
            subtitle: l10n.exportAsTextSubtitle,
            onTap: () {
              Navigator.of(context).pop();
              const ShareService().shareAllSpots(
                spots,
                l10n: l10n,
                sharePositionOrigin: sharePositionOrigin,
              );
            },
          ),
          SafeArea(top: false, child: const SizedBox(height: AppDimens.space8)),
        ],
      ),
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  const _ExportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? colorScheme.surfaceContainerHighest.withAlpha(70)
        : colorScheme.surface;

    final borderColor = colorScheme.outline.withAlpha(isDark ? 70 : 100);

    return Material(
      color: backgroundColor,
      borderRadius: AppDimens.borderRadiusLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.borderRadiusLarge,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppDimens.space16),
          decoration: BoxDecoration(
            borderRadius: AppDimens.borderRadiusLarge,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: AppDimens.borderRadiusMedium,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: AppDimens.iconMedium,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppDimens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: AppDimens.iconSmall,
                color: colorScheme.onSurfaceVariant.withAlpha(140),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
