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

                            LiquidGlassThemeSlider(
                                selectedMode: Binding(
                                    get: { env.settings.themeMode },
                                    set: { env.setTheme($0) }
                                )
                            )
                        }

                        Divider()

                        // Language Row
                        Menu {
                            Button(env.l10n.t("languageSystem")) { env.setLocale(nil) }
                            Button("English") { env.setLocale("en") }
                            Button("العربية") { env.setLocale("ar") }
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

                // Website & Contact Section
                settingsCard(title: env.l10n.isArabic ? "الموقع والتواصل" : "Website & Contact") {
                    VStack(spacing: 14) {
                        // Official Website Link
                        Link(destination: URL(string: "https://dalely.firebaseapp.com/")!) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(env.palette.primary.opacity(0.12))
                                    Image(systemName: "globe")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(env.palette.primary)
                                }
                                .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(env.l10n.isArabic ? "الموقع الرسمي" : "Official Website")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(env.palette.textPrimary)
                                    Text("https://dalely.firebaseapp.com/")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(env.palette.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(env.palette.textTertiary)
                            }
                        }

                        Divider()

                        // Privacy Policy Link
                        Link(destination: URL(string: "https://dalely.firebaseapp.com/#privacy")!) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.purple.opacity(0.12))
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.purple)
                                }
                                .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(env.l10n.isArabic ? "سياسة الخصوصية" : "Privacy Policy")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(env.palette.textPrimary)
                                    Text("https://dalely.firebaseapp.com/#privacy")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(env.palette.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(env.palette.textTertiary)
                            }
                        }

                        Divider()

                        // WhatsApp Contact
                        Button {
                            if let url = URL(string: "https://wa.me/201123225592") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.green.opacity(0.15))
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.green)
                                }
                                .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(env.l10n.isArabic ? "تواصل عبر واتساب" : "WhatsApp Support")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(env.palette.textPrimary)
                                    Text("+201123225592")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(env.palette.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(env.palette.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)

                        Divider()

                        // Email Contact
                        Button {
                            if let url = URL(string: "mailto:salem.dev.77@gmail.com") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(env.palette.car.opacity(0.15))
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(env.palette.car)
                                }
                                .frame(width: 36, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(env.l10n.isArabic ? "البريد الإلكتروني" : "Email Support")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(env.palette.textPrimary)
                                    Text("salem.dev.77@gmail.com")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(env.palette.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(env.palette.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // About Section
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
                            ShareService.shareText("Dalely - Find your spots and parked car easily: https://dalely.firebaseapp.com/", subject: "Dalely")
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
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            env.closeDetail()
                        }
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(env.palette.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(env.l10n.t("backTooltip"))
                }
            }
//
//            ToolbarItem(placement: .topBarTrailing) {
//                Button {
//                    ShareService.shareText("Dalely - Find your spots and parked car easily: https://dalely.firebaseapp.com/", subject: "Dalely")
//                } label: {
//                    Image(systemName: "square.and.arrow.up")
//                }
//            }
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
