import 'package:flutter/material.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';

/// Bottom sheet allowing the user to select their preferred language.
class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({
    super.key,
    required this.selectedLocaleCode,
    required this.onLocaleSelected,
  });

  final String? selectedLocaleCode;
  final ValueChanged<String?> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDimens.space20,
          AppDimens.space8,
          AppDimens.space20,
          AppDimens.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.translate_rounded,
                    color: context.colorScheme.primary,
                    size: AppDimens.iconMedium,
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Text(
                  l10n.language,
                  style: context.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),
            _LanguageOptionCard(
              title: l10n.languageSystem,
              icon: Icons.settings_suggest_rounded,
              isSelected: selectedLocaleCode == null,
              onTap: () {
                onLocaleSelected(null);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppDimens.space8),
            _LanguageOptionCard(
              title: l10n.languageArabicEg,
              icon: Icons.language_rounded,
              isSelected: selectedLocaleCode == 'ar_EG',
              onTap: () {
                onLocaleSelected('ar_EG');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppDimens.space8),
            _LanguageOptionCard(
              title: l10n.languageArabicSa,
              icon: Icons.language_rounded,
              isSelected: selectedLocaleCode == 'ar_SA',
              onTap: () {
                onLocaleSelected('ar_SA');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppDimens.space8),
            _LanguageOptionCard(
              title: l10n.languageEnglish,
              icon: Icons.language_rounded,
              isSelected: selectedLocaleCode == 'en',
              onTap: () {
                onLocaleSelected('en');
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer.withAlpha(isDark ? 90 : 180)
        : (isDark
            ? colorScheme.surfaceContainerHighest.withAlpha(70)
            : colorScheme.surface);

    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outline.withAlpha(isDark ? 70 : 100);

    return Material(
      color: backgroundColor,
      borderRadius: AppDimens.borderRadiusLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.borderRadiusLarge,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space12,
          ),
          decoration: BoxDecoration(
            borderRadius: AppDimens.borderRadiusLarge,
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : (isDark
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerHighest),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: AppDimens.iconSmall,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.space12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withAlpha(120),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
