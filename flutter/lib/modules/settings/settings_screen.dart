import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/constants/app_links.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/settings/settings_cubit.dart';
import '../../shared/cubits/settings/settings_state.dart';
import '../../shared/services/maps_launcher.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/adaptive_layout_ext.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/widgets/adaptive_expand_listener.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/settings_group.dart';
import 'widgets/theme_mode_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AdaptiveExpandListener(
      enabled: onClose == null,
      onExpandToTwoPane: () {
        AdaptiveNavCubit? navCubit;
        try {
          navCubit = context.read<AdaptiveNavCubit>();
        } catch (_) {}
        navCubit?.openSettings();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          right: (context.isRtl && !context.isWideScreen) || !context.isRtl,
          left: (!context.isRtl && !context.isWideScreen) || context.isRtl,

        child: Column(
          children: [
            _SettingsHeader(onClose: onClose),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
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
          // title: l10n.appearance,
          children: [
            // Theme Mode Selector
            Padding(
              padding: const EdgeInsetsDirectional.all(AppDimens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.theme,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  ThemeModeSelector(
                    currentMode: state.themeMode,
                    onModeChanged: cubit.setThemeMode,
                  ),
                ],
              ),
            ),

            // Language Pure Flutter Popup Menu Tile
            PopupMenuButton<String?>(
              tooltip: l10n.language,
              clipBehavior: Clip.antiAlias,
              elevation: 10,
              shadowColor: Colors.black.withAlpha(context.isDarkMode ? 80 : 35),
              surfaceTintColor: Colors.transparent,
              color: context.isDarkMode
                  ? const Color(0xF21E293B)
                  : const Color(0xF8FFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: AppDimens.borderRadiusMedium,
                side: BorderSide(
                  color: context.isDarkMode
                      ? Colors.white.withAlpha(25)
                      : Colors.black.withAlpha(15),
                  width: 0.5,
                ),
              ),
              onSelected: (localeCode) {
                cubit.setLocaleCode(localeCode);
              },
              itemBuilder: (menuContext) {
                final textStyle = context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                );
                return [
                  _LanguageMenuItem(
                    value: null,
                    label: l10n.languageSystem,
                    isSelected: state.localeCode == null,
                    textStyle: textStyle,
                  ),
                  _LanguageMenuItem(
                    value: 'ar_EG',
                    label: l10n.languageArabicEg,
                    isSelected: state.localeCode == 'ar_EG',
                    textStyle: textStyle,
                  ),
                  _LanguageMenuItem(
                    value: 'ar_SA',
                    label: l10n.languageArabicSa,
                    isSelected: state.localeCode == 'ar_SA',
                    textStyle: textStyle,
                  ),
                  _LanguageMenuItem(
                    value: 'en',
                    label: l10n.languageEnglish,
                    isSelected: state.localeCode == 'en',
                    textStyle: textStyle,
                  ),
                ];
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

class _LanguageMenuItem extends PopupMenuItem<String?> {
  _LanguageMenuItem({
    super.value,
    required String label,
    required bool isSelected,
    required TextStyle? textStyle,
  }) : super(
          height: 44,
          child: _LanguageMenuItemContent(
            label: label,
            isSelected: isSelected,
            textStyle: textStyle,
          ),
        );
}

class _LanguageMenuItemContent extends StatelessWidget {
  const _LanguageMenuItemContent({
    required this.label,
    required this.isSelected,
    required this.textStyle,
  });

  final String label;
  final bool isSelected;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: isSelected
              ? Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: context.colorScheme.primary,
                )
              : null,
        ),
        const SizedBox(width: AppDimens.space8),
        Text(
          label,
          style: textStyle?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
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
          children: [
            SettingsTile(
              leading: const Icon(Icons.directions_walk_rounded),
              title: l10n.carTrackingNotificationSettingTitle,
              subtitle: l10n.carTrackingNotificationSettingSubtitle,
              trailing: Switch.adaptive(
                value: state.carDistanceNotificationEnabled,
                activeTrackColor: context.colorScheme.primary,
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
      // title: l10n.about,
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
