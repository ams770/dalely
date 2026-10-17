import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/constants/app_links.dart';
import '../../shared/cubits/settings/settings_cubit.dart';
import '../../shared/cubits/settings/settings_state.dart';
import '../../shared/services/maps_launcher.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/adaptive_layout_ext.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/settings_group.dart';
import 'widgets/language_selector_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        right: context.height > 500 && context.width < 600,
        left: context.height > 500 && context.width < 600,

        child: Column(
          children: [
            _SettingsHeader(onClose: onClose),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const .all(AppDimens.space16),
                  children: const [
                    _AppearanceSection(),
                    SizedBox(height: AppDimens.space24),
                    _CarTrackingSection(),
                    SizedBox(height: AppDimens.space24),
                    _AboutSection(),
                    SizedBox(height: AppDimens.space32),
                    _SettingsFooter(),
                    SizedBox(height: AppDimens.space24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const .fromSTEB(
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space8,
      ),
      child: Row(
        children: [
          CircleIconButton(
            icon: const BackButtonIcon(),
            tooltip: l10n.backTooltip,
            onPressed: onClose ?? () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SettingsGroup(
          title: l10n.appearance,
          children: [
            // Theme Mode Segmented Selector
            Padding(
              padding: const .all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(l10n.theme, style: context.textTheme.titleMedium),
                  const SizedBox(height: AppDimens.space12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.themeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.themeDark),
                        ),
                      ],
                      selected: {state.themeMode},
                      onSelectionChanged: (newSelection) {
                        cubit.setThemeMode(newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Language Tile
            SettingsTile(
              leading: const Icon(Icons.language_rounded),
              title: l10n.language,
              trailing: Text(
                _getLanguageDisplayName(context, state.localeCode),
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => LanguageSelectorSheet(
                    selectedLocaleCode: state.localeCode,
                    onLocaleSelected: (code) {
                      cubit.setLocaleCode(code);
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getLanguageDisplayName(BuildContext context, String? code) {
    final l10n = context.l10n;
    switch (code) {
      case 'en':
        return l10n.languageEnglish;
      case 'ar_EG':
        return l10n.languageArabicEg;
      case 'ar_SA':
        return l10n.languageArabicSa;
      case 'ar':
        return l10n.languageArabic;
      default:
        return l10n.languageSystem;
    }
  }
}

class _CarTrackingSection extends StatelessWidget {
  const _CarTrackingSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SettingsCubit>();

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (prev, curr) =>
          prev.carDistanceNotificationEnabled !=
          curr.carDistanceNotificationEnabled,
      builder: (context, state) {
        return SettingsGroup(
          title: l10n.carTrackingNotificationSettingTitle,
          children: [
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.directions_walk_rounded),
              title: Text(l10n.carTrackingNotificationSettingTitle),
              subtitle: Text(
                l10n.carTrackingNotificationSettingSubtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              value: state.carDistanceNotificationEnabled,
              onChanged: (enabled) {
                cubit.setCarDistanceNotificationEnabled(enabled);
              },
            ),
          ],
        );
      },
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const launcher = MapsLauncher();

    return SettingsGroup(
      title: l10n.about,
      children: [
        SettingsTile(
          leading: const Icon(Icons.public_rounded),
          title: l10n.website,
          onTap: () => launcher.openUrl(AppLinks.website),
        ),
        SettingsTile(
          leading: const Icon(Icons.shield_outlined),
          title: l10n.privacyPolicy,
          onTap: () => launcher.openUrl(AppLinks.privacyPolicy),
        ),
        SettingsTile(
          leading: const Icon(Icons.chat_outlined),
          title: l10n.contactWhatsApp,
          onTap: () => launcher.openUrl(AppLinks.whatsApp),
        ),
        SettingsTile(
          leading: const Icon(Icons.mail_outline_rounded),
          title: l10n.contactSupport,
          onTap: () => launcher.openUrl('mailto:${AppLinks.supportEmail}'),
        ),
        // SettingsTile(
        //   leading: const Icon(Icons.rate_review_outlined),
        //   title: l10n.rateApp,
        //   onTap: () => launcher.openStoreReview(),
        // ),
      ],
    );
  }
}

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return Padding(
          padding: const .symmetric(horizontal: AppDimens.space16),
          child: Text(
            context.l10n.versionFooter(version),
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
