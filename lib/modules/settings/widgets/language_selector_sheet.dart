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

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppDimens.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.language,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          _LanguageTile(
            title: l10n.languageSystem,
            isSelected: selectedLocaleCode == null,
            onTap: () {
              onLocaleSelected(null);
              Navigator.of(context).pop();
            },
          ),
          _LanguageTile(
            title: l10n.languageEnglish,
            subtitle: 'English',
            isSelected: selectedLocaleCode == 'en',
            onTap: () {
              onLocaleSelected('en');
              Navigator.of(context).pop();
            },
          ),
          _LanguageTile(
            title: l10n.languageArabic,
            subtitle: 'العربية',
            isSelected: selectedLocaleCode == 'ar',
            onTap: () {
              onLocaleSelected('ar');
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: AppDimens.space16),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
