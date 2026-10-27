import SwiftUI

struct SettingsView: View {
    var isEmbedded: Bool = false
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                    // Appearance Section
                    settingsCard(title: env.l10n.t("appearance")) {
                        VStack(spacing: 16) {
                            // Theme Selector
                            VStack(alignment: .leading, spacing: 10) {
                                Text(env.l10n.t("theme"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(env.palette.textPrimary)

                                LiquidGlassSegmentedControl(
                                    selection: Binding(
                                        get: { env.settings.themeMode },
                                        set: { env.setTheme($0) }
                                    ),
                                    items: [AppThemeMode.system, AppThemeMode.light, AppThemeMode.dark],
                                    titleFor: { mode in
                                        switch mode {
                                        case .system: return env.l10n.t("themeSystem")
                                        case .light: return env.l10n.t("themeLight")
                                        case .dark: return env.l10n.t("themeDark")
                                        }
                                    },
                                    iconFor: { mode in
                                        switch mode {
                                        case .system: return "circle.righthalf.filled"
                                        case .light: return "sun.max.fill"
                                        case .dark: return "moon.fill"
                                        }
                                    },
                                    tintColor: env.palette.primary
                                )
                            }

                            Divider()

                            // Language Row
                            Menu {
                                Button(env.l10n.t("languageSystem")) { env.setLocale(nil) }
                                Button("English") { env.setLocale("en") }
                                Button("العربية" ) { env.setLocale("ar") }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(env.l10n.t("language"))
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(env.palette.textPrimary)
                                        Text(currentLanguageName)
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(env.palette.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(env.palette.textTertiary)
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle())
                        }
                    }

                    // Car Tracking Section
                    settingsCard(title: env.l10n.t("carTrackingSettingsHeader")) {
                        Toggle(isOn: Binding(
                            get: { env.settings.carDistanceNotificationEnabled },
                            set: { env.setCarTrackingEnabled($0) }
                        )) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(env.l10n.t("carTrackingNotificationTitle"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(env.palette.textPrimary)
                                Text(env.l10n.t("carTrackingNotificationDesc"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(env.palette.textSecondary)
                            }
                        }
                        .tint(env.palette.primary)
                    }

                    // About & Privacy Section
                    settingsCard(title: env.l10n.t("about")) {
                        VStack(spacing: 14) {
                            HStack {
                                Text(env.l10n.t("version"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(env.palette.textPrimary)
                                Spacer()
                                Text("1.0.0")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(env.palette.textSecondary)
                            }

                            Divider()

                            Button {
                                ShareService.shareText("Dalely - Find your spots and parked car easily: https://dalely.app", subject: "Dalely")
                            } label: {
                                HStack {
                                    Text(env.l10n.t("shareApp"))
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(env.palette.textPrimary)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(env.palette.primary)
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle())
                        }
                    }

                    // Privacy Note Footer
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(env.palette.primary)
                        Text(env.l10n.t("savedLocallyNote"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(env.palette.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .padding(.horizontal, AppDimens.space16)
                .padding(.vertical, 8)
                .padding(.bottom, 24)
        }
        .background(env.palette.background.ignoresSafeArea())
        .navigationTitle(env.l10n.t("settingsTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEmbedded {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        env.closeDetail()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ShareService.shareText("Dalely - Find your spots and parked car easily: https://dalely.app", subject: "Dalely")
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(env.palette.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .appCardStyle(cornerRadius: AppDimens.radiusLarge)
        }
    }

    private var currentLanguageName: String {
        switch env.settings.localeCode {
        case "ar": return "العربية"
        case "en": return "English"
        default: return env.l10n.t("languageSystem")
        }
    }
}
