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
import '../../shared/widgets/adaptive/adaptive_ui.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/settings_group.dart';

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
                  padding: const EdgeInsetsDirectional.all(AppDimens.space16),
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
      padding: const EdgeInsetsDirectional.fromSTEB(
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
          const SizedBox(width: AppDimens.space12),
          Text(
            l10n.settingsTitle,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
            // Theme Mode Adaptive Segmented Selector
            Padding(
              padding: const EdgeInsetsDirectional.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.theme, style: context.textTheme.titleMedium),
                  const SizedBox(height: AppDimens.space12),
                  AdaptiveSegmentedControl(
                    labels: [
                      l10n.themeSystem,
                      l10n.themeLight,
                      l10n.themeDark,
                    ],
                    selectedIndex: switch (state.themeMode) {
                      ThemeMode.system => 0,
                      ThemeMode.light => 1,
                      ThemeMode.dark => 2,
                    },
                    onValueChanged: (index) {
                      final mode = switch (index) {
                        0 => ThemeMode.system,
                        1 => ThemeMode.light,
                        2 => ThemeMode.dark,
                        _ => ThemeMode.system,
                      };
                      cubit.setThemeMode(mode);
                    },
                    color: context.colorScheme.primary,
                  ),
                ],
              ),
            ),

            // Language Adaptive Popup Menu Tile
            AdaptivePopupMenuButton.widget<String?>(
              items: [
                AdaptivePopupMenuItem<String?>(
                  label: l10n.languageSystem,
                  value: null,
                  selected: state.localeCode == null,
                ),
                AdaptivePopupMenuItem<String?>(
                  label: l10n.languageArabic,
                  value: 'ar',
                  selected: state.localeCode == 'ar',
                ),
                AdaptivePopupMenuItem<String?>(
                  label: l10n.languageArabicEg,
                  value: 'ar_EG',
                  selected: state.localeCode == 'ar_EG',
                ),
                AdaptivePopupMenuItem<String?>(
                  label: l10n.languageArabicSa,
                  value: 'ar_SA',
                  selected: state.localeCode == 'ar_SA',
                ),
                AdaptivePopupMenuItem<String?>(
                  label: l10n.languageEnglish,
                  value: 'en',
                  selected: state.localeCode == 'en',
                ),
              ],
              onSelected: (index, item) {
                cubit.setLocaleCode(item.value);
              },
              child: SettingsTile(
                leading: const Icon(Icons.language_rounded),
                title: l10n.language,
                trailing: Text(
                  _getLanguageDisplayName(context, state.localeCode),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
            SettingsTile(
              leading: const Icon(Icons.directions_walk_rounded),
              title: l10n.carTrackingNotificationSettingTitle,
              subtitle: l10n.carTrackingNotificationSettingSubtitle,
              trailing: AdaptiveSwitch(
                value: state.carDistanceNotificationEnabled,
                activeColor: context.colorScheme.primary,
                onChanged: (enabled) {
                  cubit.setCarDistanceNotificationEnabled(enabled);
                },
              ),
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
